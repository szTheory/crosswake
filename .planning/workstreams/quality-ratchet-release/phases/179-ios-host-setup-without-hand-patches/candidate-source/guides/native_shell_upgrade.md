# Native Shell Upgrade Guide

This guide tracks per-template-version changes to the generated iOS and Android shell projects.
Versions are listed newest-first. Each entry leads with the `RebuildPolicy.classify/2` verdict
and the named change-class atoms so you can determine the adopter action before reading the details.

The shell is host-owned after generation. Every upgrade is elective. Even OTA-safe entries
document what changed so you can make an informed decision about whether to apply the update.

Use `mix crosswake.gen.shell --diff` to compare your on-disk shell against the current templates
before deciding whether to incorporate changes.

Use `mix crosswake.shell.status` to check whether your generated shell manifest matches the
current `template_version`.

## Declared iOS host settings (Phase 179)

The iOS host build inputs now come from the ordinary `:crosswake, :ios_host`
configuration documented in [Native Shell Guide](native_shell.md#declared-ios-host-setup).
The supported keys are `router`, `origin`, `entry_route_id`, `app_bundle_id`,
`proof_app_bundle_id`, and `device_signing` (`mode` plus `team_id`). The shell test
identity is `app_bundle_id <> ".tests"`; the proof app uses the declared proof identity,
with `".tests"` and `".uitests"` suffixes for its unit and UI test targets.

The managed outputs are the host manifest, static route activation, and
`CrosswakeHostSettings.xcconfig`. `--diff` inspects those outputs and the recognized
Xcode settings migration without writing. `--check` verifies the managed outputs
against the selected declaration. Both keep diagnostics to safe paths, causes, and
repair instructions.

When `--diff` identifies an older recognized project that has not been connected to
the managed settings file, review the proposed scope and explicitly run
`mix crosswake.gen.shell ios --migrate-project-settings`, then rerun `--check`. The
migration changes only recognized shell target configuration blocks and removes the
identity/signing overrides in those blocks. It preserves unrelated PBX customizations
and host-owned Swift and entitlement files. A changed or unrecognized project structure
is refused; review its edits and restore the recognized target structure before
retrying. The migration does not replace an entire project file.

If an interrupted managed-output update is detected, inspect the staged generation,
run `mix crosswake.gen.shell ios --recover`, then rerun `--check`. Recovery restores a
coherent recognized managed state. Do not treat this as a filesystem-wide atomic
transaction: Crosswake stages the output set, publishes files individually, and uses
the recovery record to detect and repair an interrupted set.

The generated simulator configuration is explicitly unsigned. Device settings expose
the declared signing style and team for Xcode inspection, but settings inspection
does not claim signing, installation, or physical-iPhone support. Static route
activation carries no session, account, scope, media-availability, or replay authority.
Existing `mix crosswake.gen.proof_lane --config PATH` remains the separate owner for
unrelated proof-lane configuration.

---

## Template Version 2 (Phase 134 — stamp, manifest, diff)

**RebuildPolicy verdict:** `:ota_safe` — change class: `:docs_wording` (template commentary only)

### What changed

- A 2-line provenance stamp was added to all 15 stamp-eligible templates (Swift, Kotlin, Groovy,
  Properties, XML, and plist files). The stamp records the crosswake version and integer
  `template_version` at generation time.
- A `.crosswake/shell.json` manifest is now written to the per-platform generated root on every
  `mix crosswake.gen.shell` invocation. The manifest captures `crosswake_version`,
  `template_version`, `platform`, `generated_at`, and `params` (`router`, `local`, `target`).
- The `gradlew.bat` and `gradlew` scripts and `project.pbxproj` were not stamped (binary-safe
  exclusions per Phase 134 design).

### Should you rebuild?

`RebuildPolicy.classify/2` called with `:docs_wording` returns `:ota_safe`. The stamp and
manifest additions are commentary and metadata only — no native code, entitlements, permissions,
or platform configuration changed.

```
iex> RebuildPolicy.classify(:docs_wording, nil)
# Equivalent outcome: :ota_safe
```

No rebuild of the host binary is required.

### Files changed in this template version

**iOS (6 stamped templates):**
- `CrosswakeShell/CrosswakeShellApp.swift`
- `CrosswakeShell/CrosswakeCoordinator.swift`
- `CrosswakeShell/Info.plist`
- `CrosswakeShell/CrosswakeShell.entitlements`
- `CrosswakeShell/PrivacyInfo.xcprivacy`
- `CrosswakeShell.xcodeproj/xcshareddata/xcschemes/CrosswakeShell.xcscheme`

**Android (9 stamped templates):**
- `settings.gradle`
- `build.gradle`
- `gradle.properties`
- `gradle/wrapper/gradle-wrapper.properties`
- `app/build.gradle`
- `app/src/main/AndroidManifest.xml`
- `app/src/main/java/dev/crosswake/shell/MainActivity.kt`
- `app/src/main/java/dev/crosswake/shell/CrosswakeViewModel.kt`
- `app/src/main/res/values/themes.xml`

---

## Template Version 1 (initial)

**RebuildPolicy verdict:** baseline — no prior version to upgrade from.

### What changed

Template Version 1 established the initial generated shell scaffold:

- iOS Xcode project with `CrosswakeShellApp.swift`, `CrosswakeCoordinator.swift`, `Info.plist`,
  entitlements, privacy manifest, and xcscheme.
- Android Studio project with Kotlin `MainActivity`, `CrosswakeViewModel`, `AndroidManifest.xml`,
  Gradle build files, and themes.
- Bundled canonical manifest, activation, denial, and pack inventory fixtures under
  `Fixtures/` (iOS) and `app/src/main/assets/` (Android).

### Should you rebuild?

This is the baseline version. There is no prior shell to upgrade from. Run
`mix crosswake.gen.shell ios` and/or `mix crosswake.gen.shell android` to generate
Template Version 1 output.

`RebuildPolicy.classify/2` is not applicable at the initial baseline — there is no
prior template version to classify a change against.

### Files changed in this template version

All generated shell files — this is the initial scaffold.
