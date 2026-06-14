# Phase 111: Generator Rewire, Clean-Room Proof & Release - Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 10 (source files to create/modify)
**Analogs found:** 10 / 10

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/crosswake.gen.shell.ex` | Mix task | request-response (template render) | itself (lines 136-141) | exact (surgical add) |
| `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` | template | transform | itself (lines 47-63 `@local` branch) | exact (surgical line edit) |
| `priv/templates/crosswake/shell/android/app/build.gradle.eex` | template | transform | itself (lines 50-55 `@local` branch) | exact (surgical line edit) |
| `lib/crosswake/doctor/publish_readiness.ex` | service / guard | request-response (static parse) | `docs_support_parity_check/2` in same file (lines 471-500) | exact role-match |
| `test/mix/tasks/crosswake_gen_shell_test.exs` | test | CRUD | itself (lines 8-85 iOS test, 87-189 Android test) | exact (append assertions) |
| `.github/workflows/release-please.yml` (two appended jobs) | CI workflow | event-driven (post-release gate) | `publish-hex` job (lines 58-131) + `publish-android-core` job (lines 169-194) in same file | exact |
| `guides/adoption.md` | doc | — | itself (§1 reframe) | exact (surgical edit) |
| `guides/install.md` | doc | — | itself (add back-reference) | exact (one-line add) |
| `guides/support_matrix.md` | doc | — | itself (truth reconciliation) | exact |
| `CHANGELOG.md` | doc | — | existing `## [0.1.0]` section | exact (add `[0.1.2]` entry) |
| `mix.exs` | config | — | itself (`@version` line) | exact (post-cut: remove `release-as`) |
| `release-please-config.json` | config | — | itself (`"release-as"` field) | exact (post-cut: remove field) |
| `.release-please-manifest.json` | config | — | itself (`"." : "0.1.0"` baseline) | exact (release-please auto-bumps) |

---

## Pattern Assignments

### `lib/mix/tasks/crosswake.gen.shell.ex` (Mix task, template render)

**Analog:** itself — lines 136-141 are the current `render_template/3` implementation.

**Current pattern** (`lib/mix/tasks/crosswake.gen.shell.ex` lines 136-141):
```elixir
defp render_template(template_path, capabilities, local) do
  template =
    Application.app_dir(:crosswake, Path.join("priv/templates/crosswake/shell", template_path))

  EEx.eval_file(template, assigns: [capabilities: capabilities, local: local])
end
```

**Required change — add `version:` assign + `fetch_version!/0` nil-guard:**

The assigns list gets a third key `version:`. The version is fetched once before the `EEx.eval_file` call. A private `fetch_version!/0` helper tries `Application.spec(:crosswake, :vsn)` first (the installed-dep consumer path) and falls back to `Mix.Project.config()[:version]` (the source-checkout path). Both are standard Mix/OTP patterns already used elsewhere in the Elixir ecosystem. `Mix.raise/1` is the house idiom for unrecoverable task errors (see line 51 and line 57 in the same file).

**Nil-guard pattern** (`lib/mix/tasks/crosswake.gen.shell.ex` lines 50-51 and 56-57 — `Mix.raise` usage):
```elixir
Mix.raise("invalid options: #{inspect(invalid)}")
# ...
Mix.raise("usage: mix crosswake.gen.shell ios|android [--target PATH]")
```

**New `fetch_version!/0` must follow the same `Mix.raise` idiom, not `raise` or `{:error, ...}`.**

---

### `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` (template, transform)

**Analog:** its own `@local` branch (lines 47-51) for the EEx branch structure; the `<% else %>` block (lines 52-63) is the broken block to fix.

**Current broken block** (`priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` lines 52-63):
```
<% else %>
/* Begin XCRemoteSwiftPackageReference section */
		B10000010000000000000001 /* XCRemoteSwiftPackageReference "crosswake-shell-core-ios" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/crosswake/crosswake-shell-core-ios.git";
			requirement = {
				kind = exactVersion;
				version = 0.1.0;
			};
		};
/* End XCRemoteSwiftPackageReference section */
<% end %>
```

**Required replacement** (three surgical changes: org, kind, version field):
```
<% else %>
/* Begin XCRemoteSwiftPackageReference section */
		B10000010000000000000001 /* XCRemoteSwiftPackageReference "crosswake-shell-core-ios" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/szTheory/crosswake-shell-core-ios.git";
			requirement = {
				kind = upToNextMajorVersion;
				minimumVersion = <%= @version %>;
			};
		};
/* End XCRemoteSwiftPackageReference section */
<% end %>
```

Changes: `crosswake/` → `szTheory/`; `exactVersion` → `upToNextMajorVersion`; `version = 0.1.0` → `minimumVersion = <%= @version %>`. The `MARKETING_VERSION` field (adopter's app version) is NOT changed.

---

### `priv/templates/crosswake/shell/android/app/build.gradle.eex` (template, transform)

**Analog:** its own `@local` branch (lines 51-52) for EEx branch structure; line 54 is the broken line to fix.

**Current broken block** (`priv/templates/crosswake/shell/android/app/build.gradle.eex` lines 50-55):
```groovy
dependencies {
  <%= if @local do %>
  implementation project(':crosswake-shell-core-android')
  <% else %>
  implementation 'dev.crosswake:shell-core-android:0.1.0'
  <% end %>
```

**Required replacement** (line 54 only):
```groovy
  implementation("io.github.sztheory:crosswake-shell-core-android:<%= @version %>")
```

Changes: `dev.crosswake` → `io.github.sztheory` (group ID); `shell-core-android` → `crosswake-shell-core-android` (artifact ID); `0.1.0` → `<%= @version %>` (dynamic); single-quote string literal → parenthesized double-quote form. The `versionName "0.1.0"` in `defaultConfig` (adopter's Android app version) is NOT changed.

---

### `lib/crosswake/doctor/publish_readiness.ex` (service/guard, static-parse data flow)

**Analog:** `docs_support_parity_check/2` (lines 471-500) — same role (a `result_check`-based ReadinessCheck that reads files from `cwd`, asserts properties, returns blocking on failure).

**`@allowed_docs` whitelist pattern** (lines 16-25):
```elixir
@allowed_docs [
  "guides/support_matrix.md",
  "guides/compatibility.md",
  "guides/companions.md",
  "guides/commerce.md",
  "guides/native_shell.md",
  "guides/capabilities.md",
  "guides/install.md",
  "CHANGELOG.md"
]
```
Add `"guides/adoption.md"` to this list (per D-03a). No other changes to `@allowed_docs` or `docs_support_parity_check/2`.

**`result_check/1` helper pattern** (lines 569-579):
```elixir
defp result_check(opts) do
  passed? = Keyword.fetch!(opts, :passed?)

  check(
    Keyword.merge(opts,
      result: if(passed?, do: :pass, else: :fail),
      severity: if(passed?, do: :advisory, else: :error),
      blocking: not passed?
    )
  )
end
```
The new `generator_coordinate_parity_check/1` uses `result_check/1` exactly like `docs_support_parity_check/2` does — pass `passed?: ios_ok? and android_ok?` and omit `result:/severity:/blocking:` from the call site.

**`require_truth/3` pattern** (lines 610-611):
```elixir
defp require_truth(errors, true, _message), do: errors
defp require_truth(errors, false, message), do: [message | errors]
```
Already exists — reuse directly in the new check. Chain calls with `|>` as `publish_parity_check/2` does (lines 182-214).

**`docs_support_parity_check/2` as structural template** (lines 471-500):
```elixir
defp docs_support_parity_check(cwd, opts) do
  project_config = Keyword.get_lazy(opts, :project_config, &Mix.Project.config/0)
  docs = Keyword.get(project_config, :docs, [])
  extras = Keyword.get(docs, :extras, [])
  missing = Enum.reject(@allowed_docs, &(&1 in extras))
  missing_files = Enum.reject(@allowed_docs, &File.exists?(Path.join(cwd, &1)))

  result_check(
    id: "docs.support_parity",
    code:
      if(missing == [] and missing_files == [],
        do: "diag.docs.support_parity",
        else: "diag.docs.support_parity_missing"
      ),
    category: :docs_support_parity,
    passed?: missing == [] and missing_files == [],
    message:
      if(missing == [] and missing_files == [],
        do: "docs extras and support guidance cover the v3.6 readiness claim surface",
        else:
          "docs/support parity is incomplete for #{Enum.join(missing ++ missing_files, ", ")}"
      ),
    hint:
      "Keep support, compatibility, companions, commerce, native shell, capabilities, install, and changelog guidance in docs extras.",
    docs_reference: "guides/support_matrix.md",
    proof_class: :merge_blocking,
    claim_scope: "Docs/support parity",
    details: %{docs_extras: extras, missing_docs_extras: missing, missing_files: missing_files}
  )
end
```

**`build_checks/4` insertion point** (lines 161-172):
```elixir
defp build_checks(cwd, support_matrix, inspection, opts) do
  [
    publish_parity_check(cwd, opts),
    companion_dependency_health_check(inspection),
    provider_adapter_readiness_check(support_matrix, inspection),
    notification_token_readiness_check(support_matrix, inspection),
    auth_session_predicate_readiness_check(support_matrix, inspection),
    native_shell_verification_gap_check(support_matrix, inspection),
    docs_support_parity_check(cwd, opts),
    proof_posture_check(support_matrix, inspection)
  ]
end
```
Append `generator_coordinate_parity_check(cwd)` before `proof_posture_check/2` (or after — it does not depend on `support_matrix` or `inspection`).

**`check/1` struct field contract** (lines 587-608 — all `@enforce_keys` must be present):
```elixir
defp check(opts) do
  %ReadinessCheck{
    id: Keyword.fetch!(opts, :id),
    code: Keyword.fetch!(opts, :code),
    category: Keyword.fetch!(opts, :category),
    severity: Keyword.fetch!(opts, :severity),
    result: Keyword.fetch!(opts, :result),
    blocking: Keyword.fetch!(opts, :blocking),
    message: Keyword.fetch!(opts, :message),
    hint: Keyword.fetch!(opts, :hint),
    docs_reference: Keyword.fetch!(opts, :docs_reference),
    proof_class: Keyword.fetch!(opts, :proof_class),
    rebuild_requirement:
      Keyword.get(opts, :rebuild_requirement, %{
        native_required: false,
        companion_required: false,
        reasons: []
      }),
    claim_scope: Keyword.fetch!(opts, :claim_scope),
    details: Keyword.fetch!(opts, :details)
  }
end
```
`rebuild_requirement` has a default — omit it from `result_check` calls and let it default. All other fields must be provided.

**Template path convention for parity guard:** Use `Path.join(cwd, "priv/templates/crosswake/shell/...")` NOT `Application.app_dir(:crosswake, ...)`. The parity guard runs in a doctor context where the OTP app may not be started; `cwd`-relative paths work in both contexts.

---

### `test/mix/tasks/crosswake_gen_shell_test.exs` (test, unit)

**Analog:** itself — the existing iOS test (lines 8-85) and Android test (lines 87-189) are the insertion points.

**Existing iOS assertion pattern** (lines 53-56):
```elixir
assert File.read!(ios_project) =~ "PBXNativeTarget"
assert File.read!(ios_project) =~ "CrosswakeShellTests"
assert File.read!(ios_project) =~ "XCRemoteSwiftPackageReference"
refute File.read!(ios_project) =~ "XCLocalSwiftPackageReference"
```
Add coordinate assertions immediately after line 56, using the same `assert File.read!(path) =~ "..."` / `refute File.read!(path) =~ "..."` idiom.

**Existing `--local` flag test** (lines 191-220) for the `--local` refutation additions:
```elixir
test "supports --local flag for SPM and Maven dependencies" do
  # ...
  assert File.read!(ios_project) =~ "XCLocalSwiftPackageReference"
  refute File.read!(ios_project) =~ "XCRemoteSwiftPackageReference"
  # ...
  assert File.read!(android_settings) =~ "include ':crosswake-shell-core-android'"
  assert File.read!(android_app_build) =~ "implementation project(':crosswake-shell-core-android')"
end
```
Add refutations at the end of each branch block confirming remote coords do NOT appear in `--local` output.

**`tmp_dir!/1` helper** (lines 223-228):
```elixir
defp tmp_dir!(prefix) do
  path = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
  File.rm_rf!(path)
  File.mkdir_p!(path)
  path
end
```
Already defined — new test cases use it the same way.

---

### `.github/workflows/release-please.yml` — two appended jobs (CI, event-driven/post-release)

**Analog:** `publish-hex` job (lines 58-131) for `needs:` / gate / `erlef/setup-beam` / `mix local.hex` / output-passing shape; `publish-android-core` job (lines 169-194) for `actions/setup-java` and `gradlew` invocation.

**Gate pattern** (`release-please.yml` lines 60-61):
```yaml
  publish-hex:
    needs: release-please
    if: ${{ needs.release-please.outputs.releases_created == 'true' }}
```
Both new jobs use the same `if:` expression but with extended `needs:` list: `[release-please, publish-hex, publish-ios-core, publish-android-core]`.

**Hex.pm propagation poll pattern** (`release-please.yml` lines 116-130 — copy this shape for Maven Central with longer patience):
```yaml
      - name: Verify version on Hex.pm
        env:
          VERSION: ${{ needs.release-please.outputs.version }}
        run: |
          set -euo pipefail
          for i in $(seq 1 36); do
            if curl -fsS "https://hex.pm/api/packages/crosswake/releases/${VERSION}" | grep -q "\"version\""; then
              echo "Hex.pm lists crosswake ${VERSION}"
              exit 0
            fi
            echo "waiting for Hex index... (${i}/36)"
            sleep 10
          done
          echo "Timed out waiting for https://hex.pm/api/packages/crosswake/releases/${VERSION}"
          exit 1
```
Maven Central poll uses 40 attempts × 45s (30 min window). iOS mirror uses 3 attempts × 30s (near-instant, clock skew only).

**SHA-pinned actions already in the workflow** (used verbatim in new jobs):
```yaml
uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
uses: actions/setup-java@c1e323688fd81a25caa38c78aa6df2d33d3e20d9 # v4.8.0
```
All three are already pinned in the existing workflow — use identical SHAs.

**`needs.release-please.outputs.version` pin pattern** (`release-please.yml` lines 161, 118):
```yaml
      env:
        VERSION: ${{ needs.release-please.outputs.version }}
```
Used in `publish-ios-core` and `publish-hex` verify step — copy verbatim into clean-room proof steps.

**`permissions: contents: read` pattern** (all publish jobs): Each new job uses the same minimal permission declaration.

---

### `guides/adoption.md`, `guides/install.md`, `guides/support_matrix.md`, `CHANGELOG.md` (docs)

**Analog:** the files themselves — surgical edits only.

**`adoption.md` §1 change:** The sentence "Avoid generating host-owned shell code. Instead, rely on standalone dependencies to eliminate the 'eject trap'." is the target. Replace with the D-03b reframe: the generated shell is a thin host-owned wrapper whose native deps resolve from published registries. Add a header note `> For the definitive install sequence, see [guides/install.md](install.md).` near the top of the file.

**`install.md` addition:** One back-reference line near the top: `> See [guides/adoption.md](adoption.md) for offline-sync architecture context and the rationale for the generated shell pattern.`

**`CHANGELOG.md` addition:** Add a `## [0.1.2]` section. The existing `publish_parity_check/2` at lines 207-213 asserts `changelog =~ "[#{expected_version}]"` — so the section header must be present before the release PR is merged. The `no_false_shipped_claims?` check (verified strings that must be absent) must not appear in the new section. Preserve the `[Unreleased]` section with its 4 subsections.

---

### `mix.exs`, `release-please-config.json`, `.release-please-manifest.json` (config, post-cut only)

**Analog:** the files themselves.

**`mix.exs`:** The `@version "0.1.0" # x-release-please-version` marker is already in place — release-please bumps this automatically on merge. No manual edit required pre-cut; this is planner notation only.

**`release-please-config.json` post-cut removal:** The `"release-as": "0.1.2"` field in the root package config must be removed in a `chore:` commit immediately after the 0.1.2 release completes. Pattern: remove exactly that key-value pair from the root `.` package object. Commit message: `chore: remove release-as pin after 0.1.2 ships`.

---

## Shared Patterns

### EEx assigns: keyword list (all template calls)

**Source:** `lib/mix/tasks/crosswake.gen.shell.ex` line 140
**Apply to:** `render_template/3` (add `version:`), parity guard `EEx.eval_file` calls (must include all three: `capabilities: [], local: false, version: vsn`)

```elixir
EEx.eval_file(template, assigns: [capabilities: capabilities, local: local])
# Add version: to become:
EEx.eval_file(template, assigns: [capabilities: capabilities, local: local, version: version])
```

Pitfall: omitting `capabilities:` from the parity guard's `EEx.eval_file` call raises a `KeyError` at runtime, not a useful check failure. Always pass all three assigns.

### `Mix.raise/1` for unrecoverable task errors

**Source:** `lib/mix/tasks/crosswake.gen.shell.ex` lines 50-51, 56-57
**Apply to:** `fetch_version!/0` nil-guard in `crosswake.gen.shell.ex`

```elixir
Mix.raise("invalid options: #{inspect(invalid)}")
```

### `result_check/1` + `require_truth/3` pipeline for blocking ReadinessChecks

**Source:** `lib/crosswake/doctor/publish_readiness.ex` lines 569-611
**Apply to:** `generator_coordinate_parity_check/1` (new function in same module)

The pattern: build an `errors` list with `require_truth/3` pipeline, then call `result_check(passed?: errors == [], ...)`. The `result_check/1` helper sets `result:/severity:/blocking:` automatically.

### SHA-pinned GitHub Actions (all CI files)

**Source:** `.github/workflows/release-please.yml` lines 44, 70, 181
**Apply to:** both new clean-room proof jobs in `release-please.yml`

House standard: every `uses:` line must be pinned to a full commit SHA with a `# vX.Y.Z` comment. Use the SHAs already present in the file — do not introduce new unverified SHAs.

### `needs:` output propagation for release-gated jobs

**Source:** `.github/workflows/release-please.yml` lines 33-43 (outputs block), 60-61 (publish-hex gate)
**Apply to:** both new clean-room proof jobs

```yaml
outputs:
  releases_created: ${{ steps.release.outputs.releases_created }}
  tag_name: ${{ steps.release.outputs.tag_name }}
  version: ${{ steps.release.outputs.version }}
```

The clean-room jobs access `needs.release-please.outputs.version` — this works because they are jobs in the SAME workflow file, not a separate file. This is why separate-file approach was ruled out (D-01a): cross-workflow `needs:` + output access is not supported by GitHub Actions.

---

## No Analog Found

All files in this phase have direct analogs in the codebase. None require falling back to RESEARCH.md patterns exclusively.

---

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `lib/crosswake/doctor/`, `priv/templates/`, `test/mix/tasks/`, `.github/workflows/`, `guides/`
**Files read for pattern extraction:** 7 source files (gen.shell.ex, publish_readiness.ex lines 1-630, crosswake_gen_shell_test.exs, release-please.yml, project.pbxproj.eex lines 47-63, build.gradle.eex lines 48-62)
**Pattern extraction date:** 2026-06-14
