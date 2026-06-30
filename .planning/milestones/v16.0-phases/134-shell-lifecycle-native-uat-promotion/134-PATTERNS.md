# Phase 134: Shell Lifecycle + Native UAT Promotion - Pattern Map

**Mapped:** 2026-06-29
**Files analyzed:** 8 new/modified files
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/crosswake/proof/phase134_template_version_drift_test.exs` | test/proof | batch (glob → hash → assert) | `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` | exact |
| `lib/mix/tasks/crosswake.shell.status.ex` | Mix task / utility | request-response (read manifest → report + exit) | `lib/mix/tasks/crosswake.doctor.ex` | role-match |
| `lib/mix/tasks/crosswake.bump_template_version.ex` | Mix task / maintainer utility | transform (rewrite two source files) | `lib/mix/tasks/crosswake.demo.ex` (exit pattern) + `crosswake.inspect.ex` (task skeleton) | role-match |
| `lib/mix/tasks/crosswake.gen.shell.ex` (MODIFY) | Mix task / generator | file-I/O + transform | self (extend existing) | — |
| `priv/templates/crosswake/shell/{ios,android}/*.eex` (MODIFY) | config/template | transform | self (extend existing) | — |
| `guides/native_shell_upgrade.md` | docs | — | `guides/native_shell.md`, `guides/android_uat.md` | role-match |
| `.github/workflows/native-behavioral-proof-gate.yml` (MODIFY) | config/CI | event-driven | self — `android-package-unit` job block within the same file | exact |
| `guides/support_matrix.md` (MODIFY) | docs | — | self (extend existing rows) | — |

---

## Pattern Assignments

### `test/crosswake/proof/phase134_template_version_drift_test.exs` (proof test, batch)

**Analog:** `test/crosswake/proof/phase132_compat_matrix_drift_test.exs`

**Module header + alias pattern** (lines 1–28):
```elixir
defmodule Crosswake.Proof.Phase132CompatMatrixDriftTest do
  @moduledoc """
  Merge-blocking drift test for COMPAT-03.
  ...
  Stable ids (COMPAT-03):
    - proof.compat_03.doc_exists
    - proof.compat_03.non_vacuity
    ...
  """

  use ExUnit.Case, async: true

  alias Crosswake.TestSupport.ProofAssertions

  @doc_path Path.join([File.cwd!(), "guides", "companion_compatibility.md"])
  @package_glob "packages/crosswake_*/mix.exs"
```
Phase 134 mirrors this shape:
- `async: true` — read-only filesystem access, no state mutation
- `File.cwd!()` path anchor (NOT `Application.app_dir/2` — safer in test context)
- Module attributes for all static paths/globs
- `alias Crosswake.TestSupport.ProofAssertions`
- Module-level `@checked_in_hash` attribute on its own dedicated line (for `bump_template_version` regex rewrite)

**Non-vacuity guard pattern** (lines 54–67):
```elixir
test "at least two companion packages exist (non-vacuity guard)" do
  count = length(Path.wildcard(@package_glob))

  assert count >= 2,
         ProofAssertions.stable_id_message(
           "proof.compat_03.non_vacuity",
           "the drift test must compare >= 2 companion packages to avoid a vacuous pass",
           "Path.wildcard(packages/crosswake_*/mix.exs)",
           "found #{count} companion package(s) — fewer than the 2 required for a real drift comparison",
           @package_glob,
           "confirm packages/crosswake_rulestead and packages/crosswake_rindle both have a mix.exs",
           :merge_blocking
         )
end
```
Phase 134 needs TWO non-vacuity asserts (≥1 iOS AND ≥1 Android), each with a distinct stable ID.

**`ProofAssertions.stable_id_message/7` positional signature** (confirmed 7 args):
```elixir
stable_id_message(
  id,        # String — stable proof ID e.g. "proof.life_02a.template_version_drift"
  subject,   # String — human description of what is being asserted
  source,    # String — where the value was observed
  observed,  # String — what was actually found (interpolated with live values)
  path,      # String — file/glob path for context
  hint,      # String — what to do to fix it
  posture    # Atom — :merge_blocking
)
```

**Drift test body pattern** (lines 74–113 for the forward-parity loop):
```elixir
test "every companion mix.exs crosswake requirement matches the doc" do
  doc = File.read!(@doc_path)

  for mix_exs_path <- Path.wildcard(@package_glob) do
    ...
    assert some_condition,
           ProofAssertions.stable_id_message(
             "proof.compat_03.matrix_drift.#{pkg}.missing_from_doc",
             ...
             :merge_blocking
           )
  end
end
```
Phase 134 uses a simpler shape: one hash comparison (not a loop), two non-vacuity tests.

**`File.cwd!()` template path anchor** — use this pattern, NOT `Application.app_dir/2`:
```elixir
@template_dir Path.join([File.cwd!(), "priv", "templates", "crosswake", "shell"])
```

---

### `lib/mix/tasks/crosswake.shell.status.ex` (Mix task, request-response)

**Analog:** `lib/mix/tasks/crosswake.doctor.ex`

**Task skeleton pattern** (lines 1–57):
```elixir
defmodule Mix.Tasks.Crosswake.Doctor do
  use Mix.Task

  alias Crosswake.Doctor
  alias Crosswake.Doctor.Formatter
  alias Crosswake.Doctor.JSONFormatter

  @shortdoc "Diagnose Crosswake install, policy, manifest, and support truth"

  @moduledoc """
  Runs host-truth-first diagnostics over installer state...
  """

  @switches [
    format: :string,
    router: :string,
    install_manifest: :string,
    native_checks: :boolean,
    check_publish: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    ...

    output =
      case opts[:format] do
        nil -> Formatter.render(report)
        "human" -> Formatter.render(report)
        "json" -> JSONFormatter.render(report)
        other -> Mix.raise("unsupported format: #{inspect(other)}")
      end

    Mix.shell().info(output)
  end
end
```

**`--format json` pattern** — reuse the `Jason.encode! + Mix.shell().info` house style from `lib/crosswake/doctor/json_formatter.ex` (lines 43–44):
```elixir
Jason.encode!(payload, pretty: true)
# caller: Mix.shell().info(output)
```
For `shell.status`, implement inline JSON encoding (no separate formatter module needed — simpler domain):
```elixir
%{
  status: "up_to_date",
  platforms: %{
    "ios" => %{status: "up_to_date", stamped_version: 1, current_version: 1, ...},
    "android" => %{ ... }
  }
}
|> Jason.encode!(pretty: true)
|> Mix.shell().info()
```

**Exit-code pattern** — from `lib/mix/tasks/crosswake.demo.ex` (lines 41–43):
```elixir
if status != 0 do
  exit({:shutdown, status})
end
```
For `shell.status` (D-12 — three-way: 0/1/2):
```elixir
case overall_status do
  :up_to_date   -> :ok                         # Mix default exit 0
  :not_a_shell  -> :ok                         # exit 0 (non-adopter CI safe)
  {:behind, _}  -> exit({:shutdown, 2})        # exit 2
  {:error, msg} -> Mix.raise("[crosswake] shell.status: #{msg}")  # exit 1
end
```

**`[crosswake]` prefix + calm prose** — from `crosswake.doctor.ex` house style:
```elixir
Mix.shell().info("[crosswake] generated shells are up to date.")
Mix.shell().info("[crosswake] 2 template versions behind — includes a rebuild-required change.")
```

**`OptionParser.parse` with `strict:`** (lines 27):
```elixir
{opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)
if invalid != [] do
  Mix.raise("invalid options: #{inspect(invalid)}")
end
```

---

### `lib/mix/tasks/crosswake.bump_template_version.ex` (Mix task, transform)

**Analog:** `lib/mix/tasks/crosswake.inspect.ex` (task skeleton shape) + `lib/mix/tasks/crosswake.demo.ex` (file path resolution)

**Task skeleton** (lines 1–62 of inspect.ex):
```elixir
defmodule Mix.Tasks.Crosswake.Inspect do
  use Mix.Task

  @shortdoc "Inspect route-level Crosswake operator readiness"

  @moduledoc """
  Emits a route-authoritative Crosswake operator inspection document.
  """

  @switches [
    format: :string,
    router: :string
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    ...
    Mix.shell().info(output)
  end
end
```

`bump_template_version` takes no args (no `@switches` needed). Shape:
```elixir
defmodule Mix.Tasks.Crosswake.BumpTemplateVersion do
  use Mix.Task

  @shortdoc "Increment @template_version and recompute the drift test hash"

  @moduledoc """
  Maintainer task: increments the integer @template_version in gen.shell.ex
  AND recomputes + rewrites @checked_in_hash in the drift test. Run this
  whenever any .eex template changes.
  """

  @impl Mix.Task
  def run(_args) do
    # 1. Read gen.shell.ex, regex-find @template_version N, write N+1
    # 2. Recompute SHA-256 over sorted .eex templates
    # 3. Read drift test, regex-find @checked_in_hash "...", write new hash
    # 4. Mix.shell().info("[crosswake] bumped template_version to N+1; hash updated.")
  end
end
```

**Repo-root path resolution** — from `crosswake.demo.ex` (lines 31–36):
```elixir
script_path =
  __DIR__
  |> Path.join("../../..")
  |> Path.expand()
  |> Path.join("bin/see-it-run.sh")
```
For `bump_template_version`, resolve gen.shell.ex and drift test relative to `File.cwd!()` (consistent with how the drift test anchors paths). Use `File.read!/1` → `String.replace/3` with regex → `File.write!/2`.

---

### `lib/mix/tasks/crosswake.gen.shell.ex` (MODIFY — extend existing)

**Analog:** self (the file being modified)

**Current `render_template/4` assigns** (lines 152–161) — add `template_version:`:
```elixir
EEx.eval_file(
  template,
  assigns:
    [
      capabilities: capabilities,
      local: local,
      version: version
      # ADD: template_version: @template_version
    ] ++ assigns
)
```

**Current `ensure_file/2`** (lines 261–275) — do NOT use for manifest; use `File.write!/2` (D-03):
```elixir
defp ensure_file(path, contents) do
  File.mkdir_p!(Path.dirname(path))

  case File.read(path) do
    {:ok, _existing} -> :reused           # skips if present — wrong for manifest
    {:error, :enoent} ->
      File.write!(path, contents)
      :created
    {:error, reason} ->
      Mix.raise("could not create #{path}: #{:file.format_error(reason)}")
  end
end
```
For manifest: `File.mkdir_p!` + `File.write!/2` directly (always overwrite).

**`--diff` switch addition** — add to `@switches`:
```elixir
@switches [target: :string, router: :string, local: :boolean, diff: :boolean]
```
Branch before any write call (structural non-destructiveness):
```elixir
if opts[:diff] do
  Mix.shell().info("[crosswake] diff — read-only, no files changed")
  run_diff(platform, target, capabilities, local, opts)
else
  run_generate(platform, target, capabilities, local, opts)
end
```

**Line 254 replacement** (inside `shell_readme/1`):
```elixir
# BEFORE (line 254):
- Upgrade this shell with patch-or-doc guidance after generation instead of expecting safe re-ownership.

# AFTER (D-07):
- Upgrade this shell following guides/native_shell_upgrade.md for per-version changelog and rebuild guidance.
```

**`@diff_excluded_templates` pattern** for `--diff` branch — add module attribute:
```elixir
@diff_excluded_templates ["CrosswakeShell.xcodeproj/project.pbxproj"]
```

---

### `priv/templates/crosswake/shell/{ios,android}/*.eex` (MODIFY)

**Analog:** self (each template being modified)

**2-line stamp header shapes** (D-02) — add at the top of each stamp-eligible template:

Swift/Kotlin/Groovy (`//`) — stamp FIRST line:
```
// Generated by crosswake <%= @version %> (template_version: <%= @template_version %>)
// Host-owned after generation. See guides/native_shell_upgrade.md
```

Properties (`#`) — stamp FIRST line:
```
# Generated by crosswake <%= @version %> (template_version: <%= @template_version %>)
# Host-owned after generation. See guides/native_shell_upgrade.md
```

XML/plist (`<!-- -->`), AFTER the `<?xml … ?>` declaration:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Generated by crosswake <%= @version %> (template_version: <%= @template_version %>) -->
<!-- Host-owned after generation. See guides/native_shell_upgrade.md -->
```

Markdown — HTML comment at top:
```markdown
<!-- Generated by crosswake <%= @version %> (template_version: <%= @template_version %>) -->
<!-- Host-owned after generation. See guides/native_shell_upgrade.md -->
```

NO stamp in: `CrosswakeShell.xcodeproj/project.pbxproj.eex`, `gradlew.eex`, `gradlew.bat.eex`.

---

### `guides/native_shell_upgrade.md` (NEW)

**Analog:** `guides/native_shell.md` (voice) + `guides/android_uat.md` (label vocabulary)

**Voice pattern from `guides/native_shell.md`** (lines 1–16):
```markdown
# Native Shell Guide

Crosswake ships host-owned iOS and Android shells that boot from the bundled
manifest, resolve routes natively first, and fail closed when a route or bridge call
does not satisfy the declared contract.
```
- Calm/specific/actionable prose, no banned words (magic/seamless/powerful/universal)
- `[crosswake]` prefix convention applies to CLI output, not doc prose
- Code identifiers in backticks; function calls shown literally
- Host-owned contract is explicit; no "DO NOT EDIT" messaging

**Label vocabulary from `guides/android_uat.md`** (lines 3–18):
```markdown
- `JVM hermetic proof` | deterministic JVM-level CI for Android logic
- `emulator evidence` | advisory emulator output
- `rebuild-required` | a native or companion change requires rebuilding the host artifact
```

**Section structure for `native_shell_upgrade.md`** (D-06, newest-first):
```markdown
# Native Shell Upgrade Guide

## Template Version N (newest)

**RebuildPolicy verdict:** `{:rebuild_required, :native_shell}` | change class: `:permission_add`

### What changed

...

### Should you rebuild?

`RebuildPolicy.classify/2` called with this change returns `{:rebuild_required, :native_shell}`.
Rebuild the native shell artifact before shipping.

### Files changed in this template version

- `app/src/main/AndroidManifest.xml`

---

## Template Version 1 (initial)

**RebuildPolicy verdict:** baseline — no prior version to upgrade from.
```

---

### `.github/workflows/native-behavioral-proof-gate.yml` (MODIFY)

**Analog:** `android-package-unit` job block within the same file (lines 54–68)

**Existing `android-package-unit` job** — copy its shape, add `erlef/setup-beam` + `actions/setup-java`:
```yaml
android-package-unit:                    # MERGE-BLOCKING: JVM tests, no emulator (D-07)
  name: android-package-unit
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/cache@v4
      with:
        path: packages/crosswake-shell-core-android/.gradle
        key: gradle-${{ hashFiles('packages/crosswake-shell-core-android/build.gradle.kts') }}
    - name: Run Android JVM tests
      working-directory: packages/crosswake-shell-core-android
      run: ./gradlew test
    - name: Step summary
      run: |
        echo "android-package-unit: Android JVM behavioral proof passed (merge-blocking)" >> "$GITHUB_STEP_SUMMARY"
```

**New `android-generated-shell-unit` job pattern** (D-17 — extends the above shape):
```yaml
android-generated-shell-unit:            # NEW — hermetic JVM generated-shell proof (D-17)
  name: android-generated-shell-unit
  runs-on: ubuntu-latest
  env:
    CROSSWAKE_ANDROID_CONNECTED_TESTS: "0"   # hermetic JVM-only; bypasses emulator branches
  steps:
    - uses: actions/checkout@v4
    - uses: erlef/setup-beam@v1            # required: script calls mix crosswake.gen.shell
      with:
        otp-version: '27'                  # verify against other workflow pins
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

**Aggregator topology** (lines 86–96) — aggregator `needs:` is the ONLY change to this block:
```yaml
# BEFORE:
merge-blocking-native-behavioral-proof:
  name: merge-blocking-native-behavioral-proof
  if: always()
  needs: [android-package-unit]
  runs-on: ubuntu-latest
  steps:
    - name: Roll up native behavioral proof results
      uses: re-actors/alls-green@release/v1
      with:
        jobs: ${{ toJSON(needs) }}

# AFTER (D-18):
  needs: [android-package-unit, android-generated-shell-unit]
```
`if: always()` and `re-actors/alls-green` are unchanged. NEVER remove `if: always()` (D-21 footgun 1).

**Env var correctness** (D-17 pitfall — verified in `script/verify_generated_android_shell.sh` line 9):
```bash
RUN_CONNECTED_TESTS="${CROSSWAKE_ANDROID_CONNECTED_TESTS:-1}"
```
The CI job MUST set `CROSSWAKE_ANDROID_CONNECTED_TESTS: "0"` — NOT `RUN_CONNECTED_TESTS` directly.

---

### `guides/support_matrix.md` (MODIFY)

**Analog:** self (existing iOS/Android shell rows, lines 69–70)

**Current Shell Artifacts rows** (lines 69–70) — replace with Phase 134 labels (D-20):
```markdown
# CURRENT:
| ios_shell    | Hex-matched | supported | verification required | clean-room-proof-ios; ... | ...  | Default non-local scaffolds resolve... |
| android_shell| Hex-matched | supported | verification required | clean-room-proof-android; ... | ... | Default non-local scaffolds... |

# AFTER (D-20 android_shell row → merge-blocking; ios_shell stays advisory):
| android_shell | Hex-matched | supported | merge-blocking proof (JVM hermetic) | native-behavioral-proof-gate / android-generated-shell-unit | [View Boundaries](...) | JVM hermetic proof is not emulator evidence or physical-device proof. |
| ios_shell     | Hex-matched | supported | verification required              | script/verify_generated_ios_shell.sh | [View Boundaries](...) | advisory — not wired as a required CI lane; macOS/Xcode toolchain not guaranteed in CI. |
```

Existing label legend in support_matrix.md (lines 22–28) already defines the required labels:
- `merge-blocking proof` → use for android_shell
- `JVM hermetic proof` → use as qualifier, with verbatim caveat "JVM hermetic proof is not emulator evidence or physical-device proof"
- `verification required` → keep for ios_shell

---

## Shared Patterns

### `exit({:shutdown, N})` for non-zero Mix task exit codes
**Source:** `lib/mix/tasks/crosswake.demo.ex` lines 41–43
**Apply to:** `crosswake.shell.status.ex` (exit 2 for behind), `crosswake.bump_template_version.ex` (exit 1 on file write failure)
```elixir
exit({:shutdown, status})
```
Do NOT use `System.halt/2` (exits entire BEAM with no cleanup).

### `OptionParser.parse` with `strict:` + invalid guard
**Source:** `lib/mix/tasks/crosswake.doctor.ex` lines 27–30, `lib/mix/tasks/crosswake.inspect.ex` lines 21–25
**Apply to:** `crosswake.shell.status.ex`
```elixir
{opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)
if invalid != [] do
  Mix.raise("invalid options: #{inspect(invalid)}")
end
```

### `Mix.shell().info` output + `[crosswake]` prefix
**Source:** `lib/mix/tasks/crosswake.gen.shell.ex` lines 69–78, `lib/mix/tasks/crosswake.doctor.ex` line 52
**Apply to:** `crosswake.shell.status.ex`, `crosswake.bump_template_version.ex`
```elixir
Mix.shell().info("[crosswake] generated shells are up to date.")
```

### `Jason.encode!(payload, pretty: true)` for JSON output
**Source:** `lib/crosswake/doctor/json_formatter.ex` line 43
**Apply to:** `crosswake.shell.status.ex` `--format json` branch
```elixir
Jason.encode!(payload, pretty: true)
```

### `File.cwd!()` path anchor in tests
**Source:** `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` line 29
**Apply to:** `phase134_template_version_drift_test.exs`
```elixir
@template_dir Path.join([File.cwd!(), "priv", "templates", "crosswake", "shell"])
```

### `ProofAssertions.stable_id_message/7` call shape
**Source:** `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` lines 38–46
**Apply to:** `phase134_template_version_drift_test.exs`
```elixir
ProofAssertions.stable_id_message(
  "proof.life_02a.template_version_drift",  # id
  "shell templates must not change without bumping @template_version",  # subject
  "priv/templates/crosswake/shell/**/*.eex (sorted, SHA-256)",  # source
  "live hash #{live} != checked-in hash #{@checked_in_hash}",  # observed
  "priv/templates/crosswake/shell/",  # path
  "run `mix crosswake.bump_template_version` to increment @template_version and update the hash",  # hint
  :merge_blocking  # posture
)
```

### `use ExUnit.Case, async: true` for read-only proof tests
**Source:** `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` line 25
**Apply to:** `phase134_template_version_drift_test.exs`
No tags (no `:requires_example_host`, no `:engine_present`). Read-only filesystem access only.

---

## No Analog Found

All files have analogs in the codebase. No files require falling back to RESEARCH.md patterns only.

---

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `test/crosswake/proof/`, `.github/workflows/`, `guides/`, `lib/crosswake/doctor/`
**Files scanned:** 11 source files read in full
**Stable ID prefix for phase 134 tests:** `proof.life_02a.*`
**Pattern extraction date:** 2026-06-29
