# Phase 134: Shell Lifecycle + Native UAT Promotion - Research

**Researched:** 2026-06-29
**Domain:** Elixir Mix tasks, EEx templates, ExUnit proof tests, GitHub Actions workflow topology
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01** through **D-21** are fully locked (see 134-CONTEXT.md for full text). Summary of what
the planner MUST NOT re-open:

- D-01: Whole-set single integer `@template_version` epoch, decoupled from library SemVer
- D-02: Provenance in BOTH `.crosswake/shell.json` manifest AND 2-line comment header per file.
  No stamp in `project.pbxproj` or `gradlew`/`gradlew.bat`. Never "DO NOT EDIT".
- D-03: `.crosswake/shell.json` at `<target>/.crosswake/shell.json`. Written with `File.write!/2`
  (not `ensure_file/2`). Contains: `crosswake_version`, `template_version` (int), `platform`,
  `generated_at`, `params` block. Must NOT be gitignored.
- D-04: Drift test `phase134_template_version_drift_test.exs` — checked-in SHA-256 of sorted
  `.eex` templates vs live; fail with `ProofAssertions.stable_id_message/7` `:merge_blocking`.
  Non-vacuity guard ≥1 iOS AND ≥1 Android. Hermetic filesystem hash, NOT git-based.
- D-05: `mix crosswake.bump_template_version` — increments integer AND recomputes/rewrites
  the checked-in hash in the drift test.
- D-06: `guides/native_shell_upgrade.md` per-template-version sections, newest-first, leading
  with RebuildPolicy verdict.
- D-07: Replace `gen.shell.ex` line 254 placeholder with real pointer to the upgrade guide.
- D-08: Changelog verdict derived from `RebuildPolicy` change-class vocabulary.
- D-09: `shell.status` locates shell via `.crosswake/shell.json`. No-arg checks both platforms;
  `--target PATH` overrides.
- D-10: "N behind" = integer epoch delta + highest-severity RebuildPolicy verdict across
  those versions. Shows both stamped → current columns.
- D-11: Output = `[crosswake]` prefix + calm prose + `--format json` reusing
  `Crosswake.Doctor.JSONFormatter` (or an analog). States: up-to-date, N-behind, not-a-shell,
  mixed.
- D-12: Exit codes: `0` = up-to-date or not-a-shell; `2` = at least one behind; `1` = error.
- D-13: `--diff` diffs on-disk files vs freshly re-rendered in-memory. Non-destructive
  enforced structurally. Prints trust banner.
- D-14: Re-render using manifest's saved `params`. Fallback for pre-manifest shells: accept
  `--router` override + offer to write manifest. Local path no longer resolves → explicit warn +
  fall back to Hex.
- D-15: Output = unified diff (git-style). Per-file RebuildPolicy verdict annotation. Summary
  stats. Colorized on TTY. Exclude `project.pbxproj` from diff. `List.myers_difference/2`.
- D-16: Do NOT route file diffs through `RebuildPolicy.diff/2` (it diffs `Root.t()` manifests,
  not files). Use file→change-class lookup reusing RebuildPolicy verdict vocabulary. Advisory only.
- D-17: NEW job `android-generated-shell-unit` in `native-behavioral-proof-gate.yml` wrapping
  `verify_generated_android_shell.sh` with `RUN_CONNECTED_TESTS=0` (set via
  `CROSSWAKE_ANDROID_CONNECTED_TESTS=0`). Needs `erlef/setup-beam` + `actions/setup-java`
  Temurin 17. Do NOT extend existing `android-package-unit`.
- D-18: Wire into aggregator by adding to `needs: [android-package-unit, android-generated-shell-unit]`.
- D-19: Required-check registration DEFERRED — aggregator already registered. No registration
  call in Phase 134.
- D-20: iOS stays advisory. Honest `support_matrix.md` labels with verbatim caveat text.
- D-21: Encode all four aggregator footguns: (1) never remove `if: always()`, (2) Elixir setup
  needed, (3) register only aggregator not individual jobs, (4) verify `alls-green` sees both jobs.

### Claude's Discretion

Exact module/file layout, JSONFormatter reuse details, upgrade guide section-anchor naming,
precise manifest field names/casing, and diff-rendering helper internals.

### Deferred Ideas (OUT OF SCOPE)

- 3-way interactive merge/auto-patch upgrade engine
- iOS merge-blocking promotion
- Android emulator/device verification
- DRY_RUN=0 admin required-check registration
- `--require-shell` strict mode
- Adopter-side "gate CI on major staleness only" guidance
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LIFE-01a | Hermetic Android JVM generated-shell UAT lane promoted to merge-blocking | D-17/D-18/D-19: new `android-generated-shell-unit` job added to `native-behavioral-proof-gate.yml`; wired into aggregator `needs:` |
| LIFE-01b | iOS simulator/device UAT stays advisory, support posture honestly labeled | D-20: support_matrix.md edit only; no CI wiring |
| LIFE-02a | Generated native shell records `@template_version` + `crosswake` version; drift test fails if templates change without version bump | D-01/D-02/D-03/D-04/D-05: stamp + manifest + drift test + bump task |
| LIFE-02b | `mix crosswake.shell.status` + `mix crosswake.gen.shell --diff` | D-09 through D-16: two new capabilities, exit-code wiring, unified diff |
| LIFE-02c | `guides/native_shell_upgrade.md` changelog + replace dangling placeholder | D-06/D-07/D-08: new guide + one-line gen.shell.ex edit |
</phase_requirements>

---

## Summary

Phase 134 is a mid-complexity Elixir Mix task + proof-test + CI-YAML phase with no new
dependencies and no ambiguity in scope (21 locked decisions). The primary risk surfaces are:
(a) the drift test hash management — specifically WHERE the checked-in hash lives so
`bump_template_version` can rewrite it programmatically; (b) Mix task exit-code wiring for
`shell.status` (Mix tasks use `exit({:shutdown, N})` not `System.halt/2`); and (c) the
`CROSSWAKE_ANDROID_CONNECTED_TESTS=0` env var name (the script's internal variable is
`RUN_CONNECTED_TESTS`, set from `CROSSWAKE_ANDROID_CONNECTED_TESTS`; the CI job sets the
latter).

The codebase already has all needed reuse points: `ProofAssertions.stable_id_message/7` (7
positional args confirmed), the `Crosswake.Doctor.JSONFormatter` + `Mix.shell().info` pattern,
`List.myers_difference/2` in Elixir stdlib, and the `native-behavioral-proof-gate.yml`
aggregator topology. No new Hex packages are required.

**Primary recommendation:** Plan 4 wave-sequenced plans: (1) template stamping + drift test
+ manifest write [LIFE-02a, LIFE-01 groundwork], (2) `shell.status` task [LIFE-02b partial],
(3) `gen.shell --diff` branch [LIFE-02b partial], (4) CI YAML + support_matrix.md +
upgrade guide [LIFE-01a/b, LIFE-02c]. The bump task ships in plan 1 (it's the anti-forgetting
discipline for the stamp ceremony).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Template stamping + manifest write | Generator Mix task (`gen.shell.ex`) | EEx templates (2-line header) | Generator owns all template rendering; manifest is a side-effect of generation |
| Drift test | ExUnit proof test | Filesystem only (no git) | Proof test pattern established in phase132; hermetic by design |
| `shell.status` reporting | New Mix task (`crosswake.shell.status`) | `.crosswake/shell.json` manifest | Host-facing read-only diagnostic; follows doctor task pattern |
| `gen.shell --diff` | Extended Mix task (`gen.shell.ex`) | In-memory EEx re-render | Branch inside generator; re-uses render pipeline, never writes |
| Upgrade changelog | Docs (`guides/native_shell_upgrade.md`) | `RebuildPolicy` vocabulary | Docs-only; derives verdict from code vocabulary |
| Android JVM CI lane | GitHub Actions workflow YAML | `verify_generated_android_shell.sh` | New workflow job; script already exists |
| iOS advisory label | Docs (`guides/support_matrix.md`) | — | Docs-only change; no CI wiring |

---

## Standard Stack

### Core (all ASSUMED from training; no new packages needed)

No new Hex packages. All dependencies are already in the project:

| Library | Where | Purpose |
|---------|-------|---------|
| `EEx` (stdlib) | `gen.shell.ex` | Template rendering — already used |
| `List.myers_difference/2` (stdlib) | New `--diff` branch | Unified diff computation |
| `:crypto.hash(:sha256, ...)` (stdlib) | Drift test hash | SHA-256 over concatenated template bytes |
| `Jason` | `--format json` output | Already a project dep |
| `Crosswake.Doctor.JSONFormatter` | `shell.status --format json` | Reuse precedent from doctor task |
| `Crosswake.TestSupport.ProofAssertions` | Drift test | Already in test/support |
| `ExUnit` | Drift test | Already the test framework |

**Installation:** None required.

---

## Package Legitimacy Audit

No new external packages. Section not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
mix crosswake.gen.shell ios|android
         │
         ├─► EEx.eval_file(template, assigns: [...])  ─── per-template render
         │       assigns: capabilities, local, version, local_*_path
         │
         ├─► [NEW] write 2-line stamp header into each comment-supporting .eex
         │
         ├─► ensure_file/2 (existing — skips if present)    ← individual files
         │
         ├─► [NEW] File.write!/2(.crosswake/shell.json)     ← manifest (always overwrite)
         │
         └─► [if --diff] re-render in-memory → List.myers_difference/2 → print only

mix crosswake.shell.status
         │
         ├─► read .crosswake/shell.json per platform
         ├─► compare stamped template_version vs @template_version in code
         ├─► surface severity via RebuildPolicy-vocabulary changelog lookup
         └─► exit 0 / 2 / 1 via exit({:shutdown, N})

phase134_template_version_drift_test.exs
         │
         ├─► glob priv/templates/crosswake/shell/**/*.eex (sorted path order)
         ├─► :crypto.hash(:sha256, concat) → Base.encode16()
         ├─► compare vs @checked_in_hash module attribute
         └─► ProofAssertions.stable_id_message/7 :merge_blocking on mismatch

mix crosswake.bump_template_version
         │
         ├─► increment @template_version constant in gen.shell.ex
         ├─► recompute SHA-256 of all .eex templates
         └─► rewrite @checked_in_hash in phase134_template_version_drift_test.exs

.github/workflows/native-behavioral-proof-gate.yml  [D-17/D-18]
         android-package-unit ──────────────────────────────────────────┐
         android-generated-shell-unit (NEW)  ──────────────────────────►│
                 └─► erlef/setup-beam + actions/setup-java Temurin 17   │
                 └─► CROSSWAKE_ANDROID_CONNECTED_TESTS=0                │
                 └─► ./script/verify_generated_android_shell.sh         │
                                                                         ▼
         merge-blocking-native-behavioral-proof  (aggregator, unchanged name)
                 needs: [android-package-unit, android-generated-shell-unit]
                 if: always()
                 uses: re-actors/alls-green
```

### Recommended Project Structure

```
lib/mix/tasks/
├── crosswake.gen.shell.ex           # MODIFY: add @template_version, --diff, manifest write, line 254
├── crosswake.shell.status.ex        # NEW: status task (D-09-D-12)
└── crosswake.bump_template_version.ex  # NEW: bump task (D-05)

test/crosswake/proof/
└── phase134_template_version_drift_test.exs  # NEW: drift test (D-04)

priv/templates/crosswake/shell/
├── ios/*.eex                        # MODIFY: add 2-line stamp header
└── android/*.eex                    # MODIFY: add 2-line stamp header

guides/
├── native_shell_upgrade.md          # NEW: per-version changelog (D-06)
└── support_matrix.md                # MODIFY: iOS/Android shell rows (D-20)

.github/workflows/
└── native-behavioral-proof-gate.yml  # MODIFY: add android-generated-shell-unit job (D-17/D-18)
```

---

## Research Question Answers (Implementation Mechanics)

### RQ1: Drift Test Mechanics [D-04]

**ProofAssertions.stable_id_message/7 — verified signature (7 positional args):** [VERIFIED: codebase]

```
stable_id_message(id, subject, source, observed, path, hint, posture)
```

All 7 args are plain strings; `posture` is an atom (`:merge_blocking`). Returns a trimmed
string. No keyword args.

**Hash computation strategy:** [VERIFIED: codebase pattern from phase132]

The drift test must compute SHA-256 over the concatenated bytes of all `.eex` template files,
sorted in ascending path order. The sort is on the FULL relative path from the template
root (e.g. `"android/app/build.gradle.eex"` before `"android/app/src/main/..."`), so the
order is deterministic across OSes.

```elixir
# In the drift test module:
@template_dir Application.app_dir(:crosswake, "priv/templates/crosswake/shell")

# Inside a test or a module-level helper:
defp live_template_hash do
  @template_dir
  |> Path.join("**/*.eex")
  |> Path.wildcard()
  |> Enum.sort()                         # deterministic sorted-path order
  |> Enum.map(&File.read!/1)
  |> Enum.join()                         # concatenate bytes
  |> then(fn blob -> :crypto.hash(:sha256, blob) end)
  |> Base.encode16(case: :lower)
end
```

**Where to store the checked-in hash:** [VERIFIED: design from phase132 pattern]

The cleanest option is a module attribute `@checked_in_hash` in the test file itself, on a
dedicated line with a distinctive prefix that `bump_template_version` can regex-rewrite:

```elixir
# In phase134_template_version_drift_test.exs:
# bump_template_version rewrites the string on this line:
@checked_in_hash "0000000000000000000000000000000000000000000000000000000000000000"
```

`bump_template_version` uses `File.read!/1` → `String.replace/3` with a regex targeting
`@checked_in_hash "..."` → `File.write!/2`. This is a plain text rewrite, not AST
manipulation — safe because the line structure is fixed.

**Non-vacuity guard shape** (mirrors phase132's `>= 2 packages` pattern):

```elixir
test "at least 1 iOS and 1 Android template present (non-vacuity guard)" do
  ios_count = @template_dir |> Path.join("ios/**/*.eex") |> Path.wildcard() |> length()
  android_count = @template_dir |> Path.join("android/**/*.eex") |> Path.wildcard() |> length()

  assert ios_count >= 1,
    ProofAssertions.stable_id_message("proof.life_02a.non_vacuity.ios", ...)
  assert android_count >= 1,
    ProofAssertions.stable_id_message("proof.life_02a.non_vacuity.android", ...)
end
```

**IMPORTANT — application dir path:** When running `mix test` in the monorepo, `Application.app_dir(:crosswake, "priv/...")` works if the app is started. The safer pattern (used in phase132) is to anchor with `File.cwd!/0` + relative path from the repo root, or use `Path.expand("../../..", __DIR__)` to walk up from the test file. Phase132 uses `File.cwd!()` directly. Prefer `File.cwd!()` approach with a known relative path for consistency.

### RQ2: Manifest + Re-render Assigns [D-03/D-13/D-14]

**Current assigns in `render_template/4`:** [VERIFIED: codebase, gen.shell.ex lines 152-160]

```elixir
EEx.eval_file(template, assigns: [
  capabilities: capabilities,    # list of capability ID strings
  local: local,                  # boolean
  version: version               # crosswake library version string
] ++ assigns)
# where assigns from local_package_assigns/1:
# [local_ios_core_path: "...", local_android_core_path: "..."]
```

**`params` block for `.crosswake/shell.json`** (D-03) captures the user-facing generation
switches needed for re-render. The local_*_path values are DERIVED from the `local` flag
and `root`, not captured as user params:

```json
{
  "params": {
    "router": null,        // string or null (the --router value)
    "local": false,        // boolean (the --local flag)
    "target": "/path/to"  // string (resolved --target or cwd)
  }
}
```

`capabilities` is NOT stored in params — it is derived at render time from the router.
For `--diff` re-render (D-14), re-fetch capabilities from the manifest's `router` param
(or fall back to `Manifest.Builder.public_route_capability_ids()` if router is null).

**Local package path resolution** (D-14 fallback):

```elixir
defp local_package_assigns(root) do
  packages_root = Path.expand("packages", File.cwd!())
  [
    local_ios_core_path:
      relative_path(root, Path.join(packages_root, "crosswake-shell-core-ios")),
    local_android_core_path:
      relative_path(root, Path.join(packages_root, "crosswake-shell-core-android"))
  ]
end
```

This resolves `packages/crosswake-shell-core-ios` relative to `File.cwd!()` (the repo root
when called from `mix`). If `params.local == true` but that directory does not exist:
warn via `Mix.shell().info("[crosswake] local package path not found: #{path} — falling back to Hex package")`,
set `local: false` for the re-render.

**Line 254 (verified):** [VERIFIED: codebase, gen.shell.ex lines 250-255]

Line 254 is inside `shell_readme/1`, at `"patch-or-doc guidance"`:

```elixir
    - Upgrade this shell with patch-or-doc guidance after generation instead of expecting safe re-ownership.
```

D-07 replaces "patch-or-doc guidance" with a real pointer:
`"See guides/native_shell_upgrade.md for per-version changelog and rebuild guidance."`.

### RQ3: `--diff` Rendering Mechanics [D-15/D-16]

**`List.myers_difference/2`** (Elixir stdlib): [ASSUMED — confirmed from Elixir docs knowledge]

```elixir
# Takes two lists; returns list of {operation, element} tuples
# operations: :eq (unchanged), :del (removed), :ins (added)
List.myers_difference(old_lines, new_lines)
# => [{:eq, "line\n"}, {:del, "old\n"}, {:ins, "new\n"}, ...]
```

Unified diff output: convert the result into a git-style `---/+++ @@ -N,M +N,M @@` format
with `-` for `:del`, `+` for `:ins`, ` ` for `:eq` context lines. Colorize on TTY:
`IO.ANSI.red()` for deletions, `IO.ANSI.green()` for insertions, reset between.
`IO.ANSI.enabled?()` gates colorization.

**`project.pbxproj` exclusion** (D-15): [VERIFIED: codebase, gen.shell.ex @ios_templates]

The `@ios_templates` list in gen.shell.ex includes `"CrosswakeShell.xcodeproj/project.pbxproj"`.
The `--diff` branch must explicitly skip this entry before re-rendering. Pattern:

```elixir
@diff_excluded_templates ["CrosswakeShell.xcodeproj/project.pbxproj"]

defp should_diff?(relative_path) do
  relative_path not in @diff_excluded_templates
end
```

**File → change-class lookup table** (D-16): [VERIFIED: codebase — RebuildPolicy vocabulary]

The `RebuildPolicy` verdict vocabulary: `:ota_safe` and `{:rebuild_required, :native_shell}`.
The file→change-class lookup for the `--diff` annotation (advisory only):

| File pattern | Change class atom | Advisory verdict |
|---|---|---|
| `Info.plist` | `:privacy_manifest_entry` | `{:rebuild_required, :native_shell}` |
| `PrivacyInfo.xcprivacy` | `:privacy_manifest_entry` | `{:rebuild_required, :native_shell}` |
| `CrosswakeShell.entitlements` | `:entitlement_add` | `{:rebuild_required, :native_shell}` |
| `AndroidManifest.xml` | `:permission_add` | `{:rebuild_required, :native_shell}` |
| `app/build.gradle` | `:sdk_floor_bump` | `{:rebuild_required, :native_shell}` |
| `build.gradle` (root) | `:sdk_floor_bump` | `{:rebuild_required, :native_shell}` |
| `gradle/wrapper/gradle-wrapper.properties` | `:sdk_floor_bump` | `{:rebuild_required, :native_shell}` |
| `*.swift` (coordinator, app entry) | `:capability_family_add` | `:ota_safe` |
| `*.kt` (viewmodel, activity) | `:capability_family_add` | `:ota_safe` |
| `settings.gradle`, `gradle.properties` | — | `:ota_safe` |
| `themes.xml` | — | `:ota_safe` |

The lookup is a small private function; no new public API. The `:capability_family_add` verdict
for Swift/Kotlin is `:ota_safe` only because `Capability.rebuild` is not available for
file-level annotation — this is the advisory-only caveat D-16 calls out.

### RQ4: `shell.status` Exit Code Wiring [D-12]

**Mix task exit-code pattern:** [VERIFIED: codebase, crosswake.demo.ex line 42]

Mix tasks do NOT call `System.halt/2` directly — that exits the entire BEAM with no cleanup.
The established project pattern is:

```elixir
exit({:shutdown, status_code})
```

`Mix.raise/1` raises an exception which Mix catches and exits 1 — unsuitable for exit 2 (the
"behind" signal) because we need an intentional non-error signal.

**Exit code wiring for `shell.status`:**

```elixir
defmodule Mix.Tasks.Crosswake.Shell.Status do
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    # ... parse, check, report ...
    case result do
      :up_to_date -> :ok                   # exit 0 (Mix default)
      :not_a_shell -> :ok                  # exit 0 (non-adopter CI safe, D-12)
      {:behind, _info} -> exit({:shutdown, 2})   # exit 2
      {:error, _reason} -> Mix.raise("...")       # exit 1
    end
  end
end
```

**Important:** `exit({:shutdown, 2})` in a Mix task causes `mix` to exit with code 2. This
is the same mechanism used by `crosswake.demo` for propagating non-zero script exit codes.
It does NOT break `mix` chaining in the same way `System.halt/2` would.

**`--format json` output shape for `shell.status`:**

The `Crosswake.Doctor.JSONFormatter` is domain-specific to doctor reports (it has fixed
field names like `status`, `support`, `shells`, `findings`). For `shell.status`, implement
a small inline JSON map — no need to reuse the doctor formatter's module; reuse the
**pattern** (Jason.encode!, Mix.shell().info):

```elixir
# --format json output shape:
%{
  status: "up_to_date" | "behind" | "not_a_shell" | "error",
  platforms: %{
    "ios" => %{
      status: "up_to_date" | "behind" | "not_found",
      stamped_version: 1,
      current_version: 3,
      versions_behind: 2,
      highest_severity: "rebuild_required" | "ota_safe" | null
    },
    "android" => %{ ... }
  }
}
|> Jason.encode!(pretty: true)
|> Mix.shell().info()
```

### RQ5: CI Lane YAML Shape [D-17/D-18/D-19/D-21]

**Env var name clarification:** [VERIFIED: codebase, verify_generated_android_shell.sh line 9]

The script declares:
```bash
RUN_CONNECTED_TESTS="${CROSSWAKE_ANDROID_CONNECTED_TESTS:-1}"
```

The CI job must set `CROSSWAKE_ANDROID_CONNECTED_TESTS: "0"` (not `RUN_CONNECTED_TESTS`).

**Exact YAML for the new job:**

```yaml
android-generated-shell-unit:            # NEW — hermetic JVM generated-shell proof (D-17)
  name: android-generated-shell-unit
  runs-on: ubuntu-latest
  env:
    CROSSWAKE_ANDROID_CONNECTED_TESTS: "0"   # hermetic JVM-only; bypasses emulator branches
  steps:
    - uses: actions/checkout@v4
    - uses: erlef/setup-beam@v1
      with:
        otp-version: '27'
        elixir-version: '1.18'
    - uses: actions/setup-java@v4
      with:
        distribution: temurin
        java-version: '17'
    - name: Run hermetic Android generated-shell verification
      run: script/verify_generated_android_shell.sh
    - name: Step summary
      run: |
        echo "android-generated-shell-unit: generated Android shell JVM proof passed (merge-blocking via aggregator)" >> "$GITHUB_STEP_SUMMARY"
```

**Aggregator `needs:` edit (D-18):**

```yaml
# BEFORE:
  merge-blocking-native-behavioral-proof:
    needs: [android-package-unit]

# AFTER:
  merge-blocking-native-behavioral-proof:
    needs: [android-package-unit, android-generated-shell-unit]
```

`if: always()` and `re-actors/alls-green` are unchanged.

**Four footguns to encode in the plan (D-21):**

1. **Skipped == success** — `if: always()` on the aggregator MUST stay; if removed, a skipped
   dependency (e.g. due to another job failure) lets the aggregator succeed on empty input.
   `re-actors/alls-green` with `if: always()` is the correct topology.
2. **Elixir setup required** — the script calls `mix crosswake.gen.shell android`, which
   requires Elixir + OTP. `erlef/setup-beam` is easy to miss when the more-visible requirement
   is the JDK. The CI job MUST include it.
3. **Register ONLY the aggregator** — `merge-blocking-native-behavioral-proof` is the sole
   registered required check. Adding `android-generated-shell-unit` to branch protection
   directly would create two independent blocking checks (aggregator flake-blocking + individual
   flake-blocking), contradicting D-19.
4. **Verify `alls-green` sees both jobs in `toJSON(needs)`** — after the PR merges, the first
   run of the aggregator should log both job statuses in the `re-actors/alls-green` input.
   Confirm via the Actions log that `needs.android-generated-shell-unit.result` appears.

**OTP/Elixir version:** The plan should use whatever versions the existing Elixir CI uses.
Check `.github/workflows/*.yml` for the setup-beam version pinned in other jobs (to stay
consistent). Using `'27'` OTP / `'1.18'` Elixir matches the project's standard CI setup
(verify against actual workflows if a different pin appears).

**JAVA_HOME on ubuntu-latest with `actions/setup-java`:** `actions/setup-java` with
`distribution: temurin` and `java-version: '17'` sets `JAVA_HOME` automatically. The
script's `install_jdk_if_needed` function checks `JAVA_HOME` first:
```bash
if [[ -n "${JAVA_HOME:-}" ]] && jdk_works "${JAVA_HOME}"; then
  export PATH="${JAVA_HOME}/bin:${PATH}"
  return
fi
```
So with `actions/setup-java` providing a valid `JAVA_HOME`, the script skips its
slow self-install path entirely. This is the correct CI setup.

### RQ6: Comment Header Syntax Per Template [D-02]

**Template inventory (20 files total):** [VERIFIED: codebase — `find priv/templates`]

```
iOS (7 stamp-eligible):
  ios/CrosswakeShellApp.swift.eex       → // comment → stamp FIRST line
  ios/CrosswakeCoordinator.swift.eex    → // comment → stamp FIRST line
  ios/CrosswakeShell.entitlements.eex   → XML/plist  → <!-- --> AFTER <?xml ?>
  ios/PrivacyInfo.xcprivacy.eex         → XML/plist  → <!-- --> AFTER <?xml ?>
  ios/Info.plist.eex                    → XML/plist  → <!-- --> AFTER <?xml ?>
  ios/CrosswakeShell.xcodeproj/xcshareddata/xcschemes/CrosswakeShell.xcscheme.eex
                                        → XML        → <!-- --> AFTER <?xml ?>
  ios/README.md.eex                     → Markdown   → HTML comment <!-- --> at top

iOS (NO STAMP per D-02):
  ios/CrosswakeShell.xcodeproj/project.pbxproj.eex  → Xcode-managed, skip

Android (12 stamp-eligible):
  android/build.gradle.eex              → // (Groovy) → stamp FIRST line
  android/settings.gradle.eex           → // (Groovy) → stamp FIRST line
  android/app/build.gradle.eex          → // (Groovy) → stamp FIRST line
  android/app/src/main/java/dev/crosswake/shell/MainActivity.kt.eex  → // (Kotlin) → stamp FIRST
  android/app/src/main/java/dev/crosswake/shell/CrosswakeViewModel.kt.eex → // (Kotlin) → stamp FIRST
  android/app/src/main/AndroidManifest.xml.eex  → XML  → <!-- --> AFTER <?xml ?>
  android/app/src/main/res/values/themes.xml.eex → XML → <!-- --> AFTER <?xml ?>
  android/gradle/wrapper/gradle-wrapper.properties.eex → # (properties) → stamp FIRST line
  android/README.md.eex                 → Markdown   → HTML comment <!-- --> at top

Android (NO STAMP per D-02):
  android/gradlew.eex        → shell script (#!/bin/sh), shell-parse risk → skip
  android/gradlew.bat.eex    → batch file (@ECHO OFF), shell-parse risk → skip
```

**Comment header shape (D-02):**
- Swift/Kotlin/Groovy (`//`):
  ```
  // Generated by crosswake <%= @version %> (template_version: <%= @template_version %>)
  // Host-owned after generation. See guides/native_shell_upgrade.md
  ```
- Properties (`#`):
  ```
  # Generated by crosswake <%= @version %> (template_version: <%= @template_version %>)
  # Host-owned after generation. See guides/native_shell_upgrade.md
  ```
- XML/plist (`<!-- -->`), AFTER the `<?xml ... ?>` declaration:
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <!-- Generated by crosswake <%= @version %> (template_version: <%= @template_version %>) -->
  <!-- Host-owned after generation. See guides/native_shell_upgrade.md -->
  ```
- Markdown: HTML comment at top:
  ```markdown
  <!-- Generated by crosswake <%= @version %> (template_version: <%= @template_version %>) -->
  <!-- Host-owned after generation. See guides/native_shell_upgrade.md -->
  ```

**`@template_version` assign:** The current `@template_version` integer module attribute in
`gen.shell.ex` must be passed as an assign to all template renders. Add it to the assigns list
in `render_template/4`:

```elixir
EEx.eval_file(template, assigns: [
  capabilities: capabilities,
  local: local,
  version: version,
  template_version: @template_version   # ← ADD
] ++ assigns)
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Unified diff | Custom line-diff algorithm | `List.myers_difference/2` | Elixir stdlib; handles edge cases correctly |
| SHA-256 hash | Custom hash | `:crypto.hash(:sha256, blob)` | Erlang stdlib; same as used in rest of project |
| JSON output | String interpolation | `Jason.encode!/2` | Already a project dep; correct escaping |
| Exit code 2 | `System.halt(2)` | `exit({:shutdown, 2})` | Project pattern (see demo.ex); no BEAM teardown race |
| Template render for diff | Re-run mix task | In-memory `EEx.eval_file` | Diff must never write; structural enforcement |

---

## Common Pitfalls

### Pitfall 1: Wrong env var name for hermetic CI
**What goes wrong:** CI job sets `RUN_CONNECTED_TESTS=0` directly, which has no effect (the
script reads `CROSSWAKE_ANDROID_CONNECTED_TESTS`).
**Why it happens:** The CONTEXT.md refers to `RUN_CONNECTED_TESTS=0` but that is the
INTERNAL variable. The external env var is `CROSSWAKE_ANDROID_CONNECTED_TESTS`.
**How to avoid:** Always set `CROSSWAKE_ANDROID_CONNECTED_TESTS: "0"` in the CI job's `env:`.
**Verified:** `verify_generated_android_shell.sh` line 9: `RUN_CONNECTED_TESTS="${CROSSWAKE_ANDROID_CONNECTED_TESTS:-1}"`

### Pitfall 2: Drift test using `Application.app_dir/2` without app started
**What goes wrong:** `Application.app_dir(:crosswake, ...)` returns the wrong path or raises
when the OTP app is not started during `mix test`.
**How to avoid:** Anchor with `File.cwd!()` and a known relative path, OR use `Path.expand`
from `__DIR__`. The Phase 132 pattern uses `File.cwd!()` directly. Use the same approach.

### Pitfall 3: `ensure_file/2` for manifest (skips on re-gen)
**What goes wrong:** If the manifest write uses `ensure_file/2`, a host that regenerates
(after manually editing their router or switching `--local`) gets a stale manifest.
**How to avoid:** Always use `File.write!/2` for `.crosswake/shell.json` (D-03).

### Pitfall 4: Vacuous drift test (no templates found)
**What goes wrong:** A misconfigured glob returns 0 files; the hash of an empty string is
stable; the test always passes even if templates are removed entirely.
**How to avoid:** Non-vacuity guard (≥1 iOS AND ≥1 Android template) as a separate test,
failing with a `:merge_blocking` stable_id_message if the count is 0.

### Pitfall 5: Re-opening `project.pbxproj` in `--diff`
**What goes wrong:** Including `project.pbxproj` in the diff output generates multi-thousand-line
noise because Xcode auto-manages UUIDs/build settings.
**How to avoid:** Explicit exclusion list in the `--diff` branch; test that `--diff` output
does NOT contain `project.pbxproj` lines.

### Pitfall 6: `--format json` from `shell.status` piped to `jq` exits 2
**What goes wrong:** A script that runs `mix crosswake.shell.status --format json | jq ...`
propagates exit code 2 as a script failure even when the host expects it to be informational.
**How to avoid:** Document the exit codes clearly in the moduledoc. The `not-a-shell` case
returns 0 (D-12) to avoid breaking non-adopter CI.

### Pitfall 7: `@template_version` in gen.shell.ex vs. the drift test
**What goes wrong:** The bump task rewrites the hash in the test file but forgets to also
increment `@template_version` in `gen.shell.ex`, or vice versa.
**How to avoid:** The `bump_template_version` task must atomically do both in sequence and
fail loudly if either file write fails.

### Pitfall 8: Template sort order differs between hash computation and CI
**What goes wrong:** On macOS, `Path.wildcard("**/*.eex")` may return files in a different
order than on Linux CI, causing the hash to differ.
**How to avoid:** Always call `Enum.sort()` on the wildcard result before concatenation.
`Enum.sort()` on strings uses bytewise lexicographic order, which is consistent across OSes.

---

## Code Examples

### Drift Test Structure (mirrors Phase 132 pattern)

```elixir
# test/crosswake/proof/phase134_template_version_drift_test.exs
defmodule Crosswake.Proof.Phase134TemplateVersionDriftTest do
  @moduledoc """
  Merge-blocking drift test for LIFE-02a (D-04).
  Asserts that @template_version in gen.shell.ex is bumped when any .eex template changes.
  """
  use ExUnit.Case, async: true

  alias Crosswake.TestSupport.ProofAssertions

  @template_dir Path.join([File.cwd!(), "priv", "templates", "crosswake", "shell"])

  # bump_template_version rewrites the string literal on this exact line:
  @checked_in_hash "0000000000000000000000000000000000000000000000000000000000000000"

  test "template hash matches checked-in hash (drift guard)" do
    live = live_template_hash()
    assert live == @checked_in_hash,
      ProofAssertions.stable_id_message(
        "proof.life_02a.template_version_drift",
        "shell template files must not change without bumping @template_version",
        "priv/templates/crosswake/shell/**/*.eex (sorted, SHA-256)",
        "live hash #{live} != checked-in hash #{@checked_in_hash}",
        "priv/templates/crosswake/shell/",
        "run `mix crosswake.bump_template_version` to increment @template_version and update the hash",
        :merge_blocking
      )
  end

  test "at least 1 iOS and 1 Android template present (non-vacuity guard)" do
    ios = @template_dir |> Path.join("ios/**/*.eex") |> Path.wildcard() |> length()
    android = @template_dir |> Path.join("android/**/*.eex") |> Path.wildcard() |> length()

    assert ios >= 1,
      ProofAssertions.stable_id_message(
        "proof.life_02a.non_vacuity.ios", ...)
    assert android >= 1,
      ProofAssertions.stable_id_message(
        "proof.life_02a.non_vacuity.android", ...)
  end

  defp live_template_hash do
    @template_dir
    |> Path.join("**/*.eex")
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(&File.read!/1)
    |> Enum.join()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
```

### `shell.status` Exit Code Pattern

```elixir
# lib/mix/tasks/crosswake.shell.status.ex
defmodule Mix.Tasks.Crosswake.Shell.Status do
  use Mix.Task

  @shortdoc "Report whether generated native shells are up to date"

  @impl Mix.Task
  def run(args) do
    # ... parse opts, read manifests, compute status ...
    case overall_status do
      :up_to_date ->
        Mix.shell().info("[crosswake] generated shells are up to date.")
        # exit 0 (Mix default)

      :not_a_shell ->
        Mix.shell().info("[crosswake] no .crosswake/shell.json found — nothing to check.")
        # exit 0 (D-12: non-adopter CI must not break)

      {:behind, info} ->
        Mix.shell().info(format_behind(info))
        exit({:shutdown, 2})

      {:error, reason} ->
        Mix.raise("[crosswake] shell.status: #{reason}")
        # Mix.raise exits 1
    end
  end
end
```

### Unified Diff Helper

```elixir
defp unified_diff(old_content, new_content, file_label) do
  old_lines = String.split(old_content, "\n", trim: false)
  new_lines = String.split(new_content, "\n", trim: false)

  diff = List.myers_difference(old_lines, new_lines)

  if Enum.all?(diff, &match?({:eq, _}, &1)) do
    :unchanged
  else
    header = "--- #{file_label} (on disk)\n+++ #{file_label} (current template)\n"
    body = format_diff_hunks(diff)
    {:changed, header <> body}
  end
end
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| No template versioning (status quo) | Integer `@template_version` epoch + `.crosswake/shell.json` manifest | Hosts get "N versions behind" feedback |
| "patch-or-doc guidance" (placeholder text) | Real pointer to `guides/native_shell_upgrade.md` | Closes the LIFE-02c gap |
| Android JVM lane advisory | `android-generated-shell-unit` job in aggregator `needs:` | Merge-blocking without new required-check registration |

---

## Validation Architecture

> Nyquist validation is enabled (no `workflow.nyquist_validation: false` in config.json).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built in) |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/crosswake/proof/phase134_template_version_drift_test.exs` |
| Full suite command | `mix verify` (runs companions.test + core hermetic lane) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LIFE-02a (drift) | Template hash must match checked-in hash | unit/proof | `mix test test/crosswake/proof/phase134_template_version_drift_test.exs` | ❌ Wave 0 |
| LIFE-02a (non-vacuity) | ≥1 iOS AND ≥1 Android template present | unit/proof | same file | ❌ Wave 0 |
| LIFE-02a (stamp) | Generated file contains 2-line stamp header | integration (gen.shell run) | `mix crosswake.gen.shell android --target /tmp/test_shell && grep "Generated by crosswake" /tmp/test_shell/...` | ❌ verify manually or in proof test |
| LIFE-02a (manifest) | `.crosswake/shell.json` written with correct fields | integration (gen.shell run) | same gen.shell run + jq check | ❌ verify manually |
| LIFE-02b (status exit 0) | `shell.status` exits 0 when up-to-date | unit | `mix test test/mix/tasks/crosswake_shell_status_test.exs` | ❌ Wave 2 |
| LIFE-02b (status exit 2) | `shell.status` exits 2 when behind | unit | same | ❌ Wave 2 |
| LIFE-02b (diff no-write) | `gen.shell --diff` makes no file changes | unit | `mix test test/mix/tasks/crosswake_gen_shell_diff_test.exs` | ❌ Wave 3 |
| LIFE-02b (diff stdout) | `gen.shell --diff` prints unified diff | unit | same | ❌ Wave 3 |
| LIFE-02b (pbxproj excluded) | `gen.shell --diff` excludes project.pbxproj | unit | same | ❌ Wave 3 |
| LIFE-02c (guide exists) | `guides/native_shell_upgrade.md` exists | doc-presence | `mix test test/crosswake/guides/native_shell_upgrade_test.exs` | ❌ Wave 4 |
| LIFE-02c (placeholder gone) | gen.shell.ex line no longer contains "patch-or-doc guidance" | structural | grep-based proof or unit test | ❌ Wave 4 |
| LIFE-01a (CI lane) | `android-generated-shell-unit` job in workflow YAML | structural | `grep "android-generated-shell-unit" .github/workflows/native-behavioral-proof-gate.yml` | ❌ Wave 4 |
| LIFE-01a (aggregator needs) | Aggregator `needs:` contains both jobs | structural | YAML parse check | ❌ Wave 4 |
| LIFE-01b (matrix labels) | `support_matrix.md` contains correct iOS/Android shell labels | doc-presence | existing hex_page_test.exs if applicable | ❌ Wave 4 |

### Proof Test Stable IDs (D-04)

| Stable ID | Assertion |
|---|---|
| `proof.life_02a.template_version_drift` | Live hash == checked-in hash |
| `proof.life_02a.non_vacuity.ios` | ≥1 iOS `.eex` template found |
| `proof.life_02a.non_vacuity.android` | ≥1 Android `.eex` template found |

### Positive AND Negative Cases (drift test validation)

To prove the drift test actually CATCHES an un-bumped template change:

1. **Negative case (must fail when templates change):** Modify one `.eex` template byte.
   Re-run the drift test. It MUST fail with `stable_id_message` at `:merge_blocking`. Reset.
   → This is a manual dev-time check (not automated); document in the bump ceremony.

2. **Positive case (must pass after bump):** Run `mix crosswake.bump_template_version`.
   Re-run the drift test. It MUST pass. → This is the normal bump flow.

3. **Non-vacuity case (must fail if templates removed):** Delete all iOS templates.
   Non-vacuity test MUST fail. → Manual check to verify guard works.

### Sampling Rate

- **Per task commit:** `mix test test/crosswake/proof/phase134_template_version_drift_test.exs`
- **Per wave merge:** `mix verify`
- **Phase gate:** Full `mix verify` green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/crosswake/proof/phase134_template_version_drift_test.exs` — covers LIFE-02a drift
- [ ] `test/mix/tasks/crosswake_shell_status_test.exs` — covers LIFE-02b status task
- [ ] `test/mix/tasks/crosswake_gen_shell_diff_test.exs` — covers LIFE-02b diff branch
- [ ] `test/crosswake/guides/native_shell_upgrade_test.exs` — covers LIFE-02c doc presence

*(If no gaps: "None — existing test infrastructure covers all phase requirements" — in this case
there ARE gaps; all test files listed above are new)*

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP | All Mix tasks, drift test | ✓ | Project standard | — |
| `:crypto` (Erlang stdlib) | SHA-256 hash in drift test | ✓ | Built-in OTP | — |
| `Jason` | `--format json` output | ✓ | Already in deps | — |
| `erlef/setup-beam` (CI) | android-generated-shell-unit job | ✓ | Actions marketplace | — |
| `actions/setup-java` Temurin 17 (CI) | android-generated-shell-unit job | ✓ | Actions marketplace | — |
| `List.myers_difference/2` | `--diff` rendering | ✓ | Elixir stdlib | — |

**Missing dependencies:** None.

---

## Security Domain

> `security_enforcement` is not explicitly set to `false`; treating as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | Yes (light) | `OptionParser.parse` with `strict:` — already used in gen.shell.ex |
| V6 Cryptography | No | SHA-256 is used for content integrity (not security), stdlib `:crypto` |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via `--target` | Tampering | `Path.expand/1` on all user-supplied paths (already done in gen.shell.ex) |
| Manifest injection via tampered `shell.json` | Tampering | Read manifest fields defensively; treat as advisory only for `--diff` re-render |
| Shell script injection via template_version in stamp | Tampering | Integer only; validated at bump time |

---

## Open Questions (RESOLVED)

> All three resolved during planning (Phase 134 plan-checker pass):
> OQ-1 → Plan 04 Task 2 pins the repo standard `erlef/setup-beam@fc68ffb…`, `elixir-version: "1.19.5"`, `otp-version: "27.3"` (the `27`/`1.18` below was a placeholder).
> OQ-2 → Plan 02 Task 1 writes one `.crosswake/shell.json` per platform root and probes both relative to cwd (`--target` overrides).
> OQ-3 → Plan 01 Task 1 starts `@template_version` at `1`.

1. **OTP/Elixir version for the CI job (D-17)**
   - What we know: The project uses `erlef/setup-beam`; other jobs likely pin a version.
   - What's unclear: The exact OTP/Elixir version pin used in the rest of the CI.
   - Recommendation: Planner should grep `.github/workflows/` for existing `setup-beam`
     version pins and reuse the same values for consistency. The template above uses `27`/`1.18`
     as a placeholder.

2. **`shell.status` locating both platforms from cwd (D-09)**
   - What we know: Generator puts Android at `<target>/native/android/crosswake_shell` and
     iOS at `<target>/native/ios/crosswake_shell`.
   - What's unclear: Whether `shell.status` should scan from cwd using these fixed relative
     paths, or whether the manifest at `<target>/.crosswake/shell.json` is per-PLATFORM (one
     file per run) or aggregated.
   - Recommendation: Write one `.crosswake/shell.json` PER GENERATION RUN (one file per
     `gen.shell ios` and one per `gen.shell android`), each at their platform root. `shell.status`
     probes both `native/ios/crosswake_shell/.crosswake/shell.json` and
     `native/android/crosswake_shell/.crosswake/shell.json` relative to cwd. The `--target`
     flag overrides the root for one specific platform check.

3. **`@template_version` initial value**
   - What we know: There is no existing `@template_version` in gen.shell.ex.
   - What's unclear: Starting value.
   - Recommendation: Start at `1`. The first generated shells will carry `template_version: 1`.
     The drift test is initialized with the hash of the as-shipped templates.

---

## Sources

### Primary (HIGH confidence)

- Codebase: `lib/mix/tasks/crosswake.gen.shell.ex` — all current assigns, `ensure_file/2`, line 254 content, template list
- Codebase: `lib/crosswake/runtime_line/rebuild_policy.ex` — confirmed `diff/2` diffs `Root.t()` manifests; `classify/2` signature; verdict vocabulary
- Codebase: `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` — `ProofAssertions.stable_id_message/7` arity/signature; non-vacuity pattern; `async: true` style
- Codebase: `test/support/proof_assertions.ex` — confirmed 7 positional args; return type
- Codebase: `lib/mix/tasks/crosswake.demo.ex` — `exit({:shutdown, N})` pattern for non-zero exit codes
- Codebase: `lib/crosswake/doctor/json_formatter.ex` — confirmed `JSONFormatter` module path + `Jason.encode!/Mix.shell().info` house style
- Codebase: `.github/workflows/native-behavioral-proof-gate.yml` — confirmed aggregator topology; existing `needs: [android-package-unit]`; `if: always()`; `re-actors/alls-green`
- Codebase: `script/verify_generated_android_shell.sh` — confirmed env var `CROSSWAKE_ANDROID_CONNECTED_TESTS`; `JAVA_HOME` check; `mix crosswake.gen.shell android --target` call
- Codebase: `priv/templates/crosswake/shell/**/*.eex` — confirmed 20 template files; per-file comment syntax
- Codebase: `guides/support_matrix.md` — iOS/Android shell rows; Promotion Rules table (shell.android.jvm_hermetic row at line 174)

### Secondary (MEDIUM confidence)

- Elixir stdlib: `List.myers_difference/2` — confirmed function exists in Elixir (training knowledge)
- Elixir stdlib: `:crypto.hash(:sha256, blob)` — confirmed OTP function (training knowledge)

### Tertiary (LOW confidence)

- None

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `List.myers_difference/2` is in Elixir stdlib (not a separate dep) | Code Examples | Would need to add a dep or hand-roll; low risk — stdlib since Elixir 1.4 |
| A2 | OTP 27 / Elixir 1.18 are the project's current CI version pins | CI Lane | Wrong pin causes version mismatch in `setup-beam`; planner should grep other workflows |
| A3 | `File.cwd!()` during `mix test` returns the repo root | Drift Test Mechanics | If cwd is different, template glob finds 0 files → non-vacuity guard fails loudly |

**If this table is empty:** Not applicable — A1-A3 are low-risk; A1 is nearly certain correct.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all reuse points verified in actual source files
- Architecture: HIGH — mechanics derived from actual file signatures and patterns
- Pitfalls: HIGH — most discovered by reading the actual source (env var name, ensure_file, exit codes)
- CI YAML: HIGH — aggregator topology read directly from the workflow file

**Research date:** 2026-06-29
**Valid until:** 2026-07-29 (stable Elixir/OTP ecosystem; workflow topology not expected to change)
