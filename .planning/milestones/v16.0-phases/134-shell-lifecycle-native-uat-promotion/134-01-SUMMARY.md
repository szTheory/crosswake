---
phase: "134"
plan: "01"
subsystem: shell-lifecycle
tags: [life-02a, template-version, stamp, manifest, drift-test, bump]
dependency_graph:
  requires:
    - test/crosswake/proof/phase134_template_version_drift_test.exs (Plan 00)
  provides:
    - lib/mix/tasks/crosswake.gen.shell.ex (@template_version, template_version/0, manifest write)
    - priv/templates/crosswake/shell/**/*.eex (15 stamped templates)
    - lib/mix/tasks/crosswake.bump_template_version.ex
    - test/mix/tasks/crosswake_gen_shell_stamp_test.exs
  affects:
    - Plans 02/03 (shell.status + gen.shell --diff consume template_version/0 and shell.json manifest)
    - Plan 04 (drift test stays GREEN through template changes when bump is run)
tech_stack:
  added:
    - Jason.encode!/2 for manifest serialization (already a project dep)
    - :crypto.hash(:sha256, ...) for template hash computation (OTP stdlib)
  patterns:
    - File.write!/2 (always overwrite) for manifest — never ensure_file/2 (skips when present)
    - @template_version module attribute as integer epoch (decoupled from SemVer)
    - Public template_version/0 accessor as single source of truth for Plans 02/03
    - Sorted glob → SHA-256 → Base.encode16(case: :lower) as drift-hash algorithm
    - bump_template_version: atomic two-file edit (gen.shell.ex + drift test) in one command
key_files:
  created:
    - lib/mix/tasks/crosswake.bump_template_version.ex
    - test/mix/tasks/crosswake_gen_shell_stamp_test.exs
  modified:
    - lib/mix/tasks/crosswake.gen.shell.ex
    - priv/templates/crosswake/shell/ios/CrosswakeShellApp.swift.eex
    - priv/templates/crosswake/shell/ios/CrosswakeCoordinator.swift.eex
    - priv/templates/crosswake/shell/ios/Info.plist.eex
    - priv/templates/crosswake/shell/ios/CrosswakeShell.entitlements.eex
    - priv/templates/crosswake/shell/ios/PrivacyInfo.xcprivacy.eex
    - priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/xcshareddata/xcschemes/CrosswakeShell.xcscheme.eex
    - priv/templates/crosswake/shell/android/build.gradle.eex
    - priv/templates/crosswake/shell/android/settings.gradle.eex
    - priv/templates/crosswake/shell/android/gradle.properties.eex
    - priv/templates/crosswake/shell/android/app/build.gradle.eex
    - priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/MainActivity.kt.eex
    - priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/CrosswakeViewModel.kt.eex
    - priv/templates/crosswake/shell/android/app/src/main/AndroidManifest.xml.eex
    - priv/templates/crosswake/shell/android/app/src/main/res/values/themes.xml.eex
    - priv/templates/crosswake/shell/android/gradle/wrapper/gradle-wrapper.properties.eex
    - test/crosswake/proof/phase134_template_version_drift_test.exs
    - test/mix/tasks/crosswake_gen_shell_test.exs
decisions:
  - "@template_version shipped as epoch 2: stamp was a genuine template change (Plan 00 shipped unstamped templates), so bump ceremony from 1→2 is correct"
  - "router opt passed through generate_ios_shell/4 and generate_android_shell/4 so manifest params.router captures the actual --router flag value"
  - "Stamp placed after <?xml ?> prolog for all XML/plist templates to maintain well-formed XML (prolog must be first line)"
  - "crosswake_gen_shell_test.exs fixed to include template_version in direct EEx.eval_file assigns (eliminates assign warning from stamped templates)"
metrics:
  duration: "~9 minutes"
  completed: "2026-06-29"
  tasks_completed: 4
  files_created: 2
  files_modified: 18
status: complete
---

# Phase 134 Plan 01: Template Version Stamp + Manifest + Bump Task Summary

Keystone of Phase 134 (D-01..D-05). Every generated shell file now carries a readable 2-line provenance stamp (crosswake version + integer template_version epoch), a `.crosswake/shell.json` manifest is written on every generation run, the drift test is GREEN and catches un-bumped template changes, and `mix crosswake.bump_template_version` performs the complete bump ceremony in one command.

## What Was Built

**Task 1 — @template_version + manifest write + public accessor (`lib/mix/tasks/crosswake.gen.shell.ex`):**

- Added `@template_version 1` module attribute (integer epoch, decoupled from library SemVer per D-01)
- Added `template_version: @template_version` to `render_template/4` assigns so all templates can interpolate `<%= @template_version %>`
- Added public `def template_version, do: @template_version` with `@spec template_version() :: pos_integer()` and `@doc` — the single source of truth Plans 02/03 consume (REVIEW FIX finding 3)
- Added `write_shell_manifest/5` writing `<root>/.crosswake/shell.json` via `File.write!/2` (always overwrite — not `ensure_file/2` which skips when present, D-03 pitfall 3)
- Manifest location: `<target>/native/<platform>/crosswake_shell/.crosswake/shell.json` (per-platform generated root, REVIEW FIX finding 1)
- Manifest fields: `crosswake_version`, `template_version`, `platform`, `generated_at` (ISO8601), `params{router, local, target}`, `_comment` do-not-hand-edit key
- Passed `router` opt through `generate_ios_shell/4` and `generate_android_shell/4` to capture the actual `--router` flag value in the manifest

**Task 2 — 15 stamp-eligible templates stamped + generated-output test:**

Stamp-eligible set = @ios_templates + @android_templates MINUS D-02 exclusions (project.pbxproj, gradlew, gradlew.bat):
- iOS (6): `CrosswakeShellApp.swift`, `CrosswakeCoordinator.swift`, `Info.plist`, `CrosswakeShell.entitlements`, `PrivacyInfo.xcprivacy`, `CrosswakeShell.xcscheme`
- Android (9): `settings.gradle`, `build.gradle`, `gradle.properties`, `gradle-wrapper.properties`, `app/build.gradle`, `AndroidManifest.xml`, `MainActivity.kt`, `CrosswakeViewModel.kt`, `themes.xml`

Comment syntax applied correctly:
- Swift/Kotlin/Groovy → `//` prefix as first 2 lines
- Properties → `#` prefix as first 2 lines
- XML/plist → `<!-- -->` immediately AFTER `<?xml ?>` declaration (prolog stays first line, well-formed XML)

Created `test/mix/tasks/crosswake_gen_shell_stamp_test.exs` (5 tests, all GREEN):
- Positive: all iOS stamped files carry the marker
- Positive: all Android stamped files carry the marker
- Regression guard: `gradle.properties` specifically asserts `# Generated by crosswake` (REVIEW FIX finding 4 correction a)
- Negative: project.pbxproj, gradlew, gradlew.bat have NO stamp
- Content: stamp includes `(template_version:` substring

Also fixed `crosswake_gen_shell_test.exs` to add `template_version:` to direct EEx assigns.

**Task 3 — `mix crosswake.bump_template_version` task:**

Implements the 3-step atomic bump ceremony:
1. Regex-finds `@template_version N` in `gen.shell.ex`, writes N+1
2. Recomputes SHA-256: `Path.wildcard("priv/templates/crosswake/shell/**/*.eex") |> Enum.sort() |> Enum.map(&File.read!/1) |> Enum.join() |> :crypto.hash(:sha256, &1) |> Base.encode16(case: :lower)` — identical byte-for-byte to the drift test's `live_template_hash/0`
3. Regex-replaces `@checked_in_hash "..."` in the drift test with the new hash

Both edits happen atomically in one command — fails loudly (`Mix.raise`) if either regex is not found.

**Task 4 — Run bump ceremony, turn drift test GREEN:**

Ran `mix crosswake.bump_template_version` once:
- `@template_version` incremented from 1 to 2
- `@checked_in_hash` updated to `54ca60edcbe7f16826b782514492c48c4d8d67d8d1b81ad0fb1e40b5b97b0454` (replaces all-zero Plan 00 placeholder)

**Chosen @template_version shipped value: 2.** The stamps were a genuine template change (Plan 00 shipped the templates without stamps), so running the bump once to capture the stamped template bytes at epoch 2 is the correct ceremony. The stamp in every generated file and the manifest both record `template_version: 2`.

Drift test result: **3 tests, 0 failures** (drift guard GREEN, both non-vacuity tests GREEN).

## Verification Results

```
# Task 1 verification:
manifest exists at per-platform root (android):
  /tmp/cw_stamp_test/native/android/crosswake_shell/.crosswake/shell.json
manifest fields present: crosswake_version, template_version, platform, generated_at, params
Re-run overwrites manifest (different generated_at timestamps)
Mix.Tasks.Crosswake.Gen.Shell.template_version/0 returns: 2

# Task 2 verification:
5 tests, 0 failures (crosswake_gen_shell_stamp_test.exs)
gradle.properties: # Generated by crosswake
project.pbxproj: no stamp (correct)
gradlew: no stamp (correct)
XML prolog remains first line (<?xml version="1.0" ...?>)

# Task 3 verification:
mix help crosswake.bump_template_version: registered
mix compile --warnings-as-errors: clean

# Task 4 verification:
mix test test/crosswake/proof/phase134_template_version_drift_test.exs: 3 tests, 0 failures
@checked_in_hash: 54ca60edcbe7f16826b782514492c48c4d8d67d8d1b81ad0fb1e40b5b97b0454 (real hash)
@template_version: 2 (in gen.shell.ex, manifest, and stamps)

# Full suite regression:
1200 tests, 2 failures (10 excluded)
  — 2 remaining failures are Plan 00 RED scaffolds for Plan 04 (native_shell_upgrade.md guide)
  — drift test moved from 3 failures (Plan 00) to 0 failures (Plan 01)
```

## Negative-Case Drift-Catch Result

Mutated `priv/templates/crosswake/shell/android/build.gradle.eex` by appending one comment line. The drift test failed with:
```
[proof.life_02a.template_version_drift] posture=merge_blocking
subject=shell templates must not change without bumping @template_version
observed=live hash 14a4549c... != checked-in hash 54ca60ed...
hint=run `mix crosswake.bump_template_version` to increment @template_version and update the hash
```
Result: **merge-blocking failure confirmed**. Reverted mutation — drift test immediately returned GREEN (3/0).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed crosswake_gen_shell_test.exs direct EEx.eval_file assigns missing template_version**
- **Found during:** Task 2 verification
- **Issue:** Existing test called `EEx.eval_file` directly with `assigns = [local: false, version: version, capabilities: []]`. After adding `@template_version` to stamped templates, this produced an `assign @template_version not available in EEx template` warning for `app/build.gradle.eex`
- **Fix:** Added `template_version: Mix.Tasks.Crosswake.Gen.Shell.template_version()` to the assigns in that test
- **Files modified:** `test/mix/tasks/crosswake_gen_shell_test.exs`
- **Commit:** 5153d8f

**2. [Rule 2 - Missing critical functionality] Passed router opt through generation flow**
- **Found during:** Task 1 implementation
- **Issue:** `generate_ios_shell/3` and `generate_android_shell/3` did not receive the `--router` flag value, so the manifest `params.router` field would always be `nil` even when a router was specified
- **Fix:** Changed function signatures to `generate_ios_shell/4` and `generate_android_shell/4`, threading the `router` opt from `run/1` through to `write_shell_manifest/5`
- **Files modified:** `lib/mix/tasks/crosswake.gen.shell.ex`
- **Commit:** e11a744

## Known Stubs

None — all artifacts are fully implemented and functional.

## Threat Surface Scan

T-134-01-01 (mitigate): `Path.expand/1` on target is already in `gen.shell.ex:71` — confirmed present. The manifest `params.target` records the expanded path (host-local provenance, not published).
T-134-01-02 (mitigate): `@template_version` is a compile-time integer attribute; no user input is interpolated into the version field.
T-134-01-03 (accept): Manifest `target` field records absolute path — host-local, not published. Accepted per threat register.
T-134-01-04 (mitigate): `File.write!/2` used for manifest (not `ensure_file/2`) — always overwrites, never skips.

No new threat surface beyond what the plan modeled.

## Self-Check: PASSED

- FOUND: lib/mix/tasks/crosswake.gen.shell.ex (@template_version 2, template_version/0, write_shell_manifest/5)
- FOUND: lib/mix/tasks/crosswake.bump_template_version.ex
- FOUND: test/mix/tasks/crosswake_gen_shell_stamp_test.exs
- FOUND: test/crosswake/proof/phase134_template_version_drift_test.exs (@checked_in_hash real, not all-zeros)
- FOUND: commit e11a744 (Task 1 — gen.shell.ex)
- FOUND: commit 5153d8f (Task 2 — 15 templates stamped + stamp test)
- FOUND: commit 2eaa408 (Task 3 — bump_template_version task)
- FOUND: commit 102090a (Task 4 — bump run, drift test GREEN)
